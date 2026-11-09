internal import Binary
public import Byte

extension W3C_PNG {

    private static let signature: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].map(Byte.init(bitPattern:))

    public static func parse(_ data: [Byte]) throws(ParseError) -> Image {

        guard data.count >= 8,
            data[0..<8].elementsEqual(signature)
        else {
            throw .invalidSignature
        }

        var offset = 8
        var ihdr: IHDR?
        var idatData: [Byte] = []
        var palette: [PaletteEntry]?

        while offset + 12 <= data.count {
            let length = Int(readUInt32BE(data, at: offset))
            let chunkType = String(decoding: data[(offset + 4)..<(offset + 8)], as: UTF8.self)
            let chunkDataStart = offset + 8
            let chunkDataEnd = chunkDataStart + length

            guard chunkDataEnd + 4 <= data.count else { break }

            guard CRC.checksum(data[(offset + 4)..<chunkDataEnd]) == readUInt32BE(data, at: chunkDataEnd) else {
                throw .crcMismatch
            }

            switch chunkType {
            case "IHDR":
                ihdr = try parseIHDR(Array(data[chunkDataStart..<chunkDataEnd]))

            case "PLTE":
                palette = try parsePLTE(Array(data[chunkDataStart..<chunkDataEnd]))

            case "IDAT":
                idatData.append(contentsOf: data[chunkDataStart..<chunkDataEnd])

            case "IEND":
                break

            default:

                break
            }

            offset = chunkDataEnd + 4
        }

        guard let header = ihdr else {
            throw .missingIHDR
        }

        guard !idatData.isEmpty else {
            throw .missingIDAT
        }

        if header.colorType == .indexed && palette == nil {
            throw .missingPalette
        }

        var decompressed: [Byte] = []
        do throws(RFC_1950.Error) {
            try RFC_1950.decompress(idatData, into: &decompressed)
        } catch {
            throw .decompressionFailed
        }

        let rawPixels =
            if header.isInterlaced {
                try deinterlace(
                    decompressed,
                    width: header.width,
                    height: header.height,
                    colorType: header.colorType,
                    bitDepth: header.bitDepth
                )
            } else {
                try reverseFilters(
                    decompressed,
                    width: header.width,
                    height: header.height,
                    colorType: header.colorType,
                    bitDepth: header.bitDepth
                )
            }

        return Image(
            width: header.width,
            height: header.height,
            colorType: header.colorType,
            bitDepth: header.bitDepth,
            rawPixels: rawPixels,
            palette: palette
        )
    }
}

extension W3C_PNG {

    private struct IHDR {
        let width: Int
        let height: Int
        let bitDepth: Int
        let colorType: ColorType
        let isInterlaced: Bool
    }

    private static func parseIHDR(_ data: [Byte]) throws(ParseError) -> IHDR {
        guard data.count >= 13 else {
            throw .invalidIHDR
        }

        let width = Int(readUInt32BE(data, at: 0))
        let height = Int(readUInt32BE(data, at: 4))
        guard (1...Int(Int32.max)).contains(width), (1...Int(Int32.max)).contains(height) else {
            throw .invalidIHDR
        }
        let bitDepth = Int(data[8].underlying)
        let colorTypeRaw = data[9].underlying

        guard let colorType = ColorType(rawValue: colorTypeRaw) else {
            throw .unsupportedColorType(data[9])
        }

        let validBitDepths: [Int]
        switch colorType {
        case .grayscale:
            validBitDepths = [1, 2, 4, 8, 16]

        case .rgb, .grayscaleAlpha, .rgba:
            validBitDepths = [8, 16]

        case .indexed:
            validBitDepths = [1, 2, 4, 8]
        }

        guard validBitDepths.contains(bitDepth) else {
            throw .unsupportedBitDepth(bitDepth)
        }

        guard data[10].underlying == 0, data[11].underlying == 0 else {
            throw .invalidIHDR
        }

        let isInterlaced: Bool
        switch data[12].underlying {
        case 0:
            isInterlaced = false

        case 1:
            isInterlaced = true

        default:
            throw .invalidIHDR
        }

        return IHDR(
            width: width,
            height: height,
            bitDepth: bitDepth,
            colorType: colorType,
            isInterlaced: isInterlaced
        )
    }
}

extension W3C_PNG {
    private static func parsePLTE(_ data: [Byte]) throws(ParseError) -> [PaletteEntry] {
        guard data.count % 3 == 0 && data.count >= 3 && data.count <= 768 else {
            throw .invalidPalette
        }

        var palette: [PaletteEntry] = []
        palette.reserveCapacity(data.count / 3)

        for i in stride(from: 0, to: data.count, by: 3) {
            palette.append(PaletteEntry(r: data[i], g: data[i + 1], b: data[i + 2]))
        }

        return palette
    }
}

extension W3C_PNG {

    private static func reverseFilters(
        _ data: [Byte],
        width: Int,
        height: Int,
        colorType: ColorType,
        bitDepth: Int
    ) throws(ParseError) -> [Byte] {
        let channels = colorType.channels
        let bitsPerPixel = channels * bitDepth
        let bytesPerPixel = (bitsPerPixel + 7) / 8
        let bitsPerScanline = width.multipliedReportingOverflow(by: bitsPerPixel)
        guard !bitsPerScanline.overflow else { throw .invalidDataSize }
        let scanlineBytes = (bitsPerScanline.partialValue + 7) / 8
        let scanlineWithFilter = scanlineBytes + 1

        let required = height.multipliedReportingOverflow(by: scanlineWithFilter)
        guard !required.overflow, data.count >= required.partialValue else {
            throw .invalidDataSize
        }

        var result: [Byte] = []
        result.reserveCapacity(height * scanlineBytes)

        var previousScanline = [Byte](repeating: Byte(0), count: scanlineBytes)

        for y in 0..<height {
            let scanlineStart = y * scanlineWithFilter
            let filterByte = data[scanlineStart].underlying

            guard let filterType = FilterType(rawValue: filterByte) else {
                throw .invalidFilter(data[scanlineStart])
            }

            let rawScanline = Array(
                data[(scanlineStart + 1)..<(scanlineStart + scanlineWithFilter)]
            )
            let filteredScanline = applyReverseFilter(
                filterType,
                scanline: rawScanline,
                previous: previousScanline,
                bytesPerPixel: bytesPerPixel
            )

            result.append(contentsOf: filteredScanline)
            previousScanline = filteredScanline
        }

        return result
    }

    private static func applyReverseFilter(
        _ filter: FilterType,
        scanline: [Byte],
        previous: [Byte],
        bytesPerPixel: Int
    ) -> [Byte] {
        var result = scanline

        switch filter {
        case .none:
            break

        case .sub:
            (bytesPerPixel..<result.count).forEach { i in
                result[i] = Byte(result[i].underlying &+ result[i - bytesPerPixel].underlying)
            }

        case .up:
            result.indices.forEach { i in
                result[i] = Byte(result[i].underlying &+ previous[i].underlying)
            }

        case .average:
            result.indices.forEach { i in
                let a = i >= bytesPerPixel ? Int(result[i - bytesPerPixel].underlying) : 0
                let b = Int(previous[i].underlying)
                result[i] = Byte(result[i].underlying &+ UInt8((a + b) / 2))
            }

        case .paeth:
            result.indices.forEach { i in
                let a = i >= bytesPerPixel ? Int(result[i - bytesPerPixel].underlying) : 0
                let b = Int(previous[i].underlying)
                let c = i >= bytesPerPixel ? Int(previous[i - bytesPerPixel].underlying) : 0
                result[i] = Byte(result[i].underlying &+ UInt8(paethPredictor(a, b, c)))
            }
        }

        return result
    }

    private static func paethPredictor(_ a: Int, _ b: Int, _ c: Int) -> Int {
        let p = a + b - c
        let pa = abs(p - a)
        let pb = abs(p - b)
        let pc = abs(p - c)

        return if pa <= pb && pa <= pc {
            a
        } else if pb <= pc {
            b
        } else {
            c
        }
    }
}

extension W3C_PNG {

    private struct Adam7Pass {
        let xStart: Int
        let yStart: Int
        let xStep: Int
        let yStep: Int
    }

    private static let adam7Passes: [Adam7Pass] = [
        Adam7Pass(xStart: 0, yStart: 0, xStep: 8, yStep: 8),
        Adam7Pass(xStart: 4, yStart: 0, xStep: 8, yStep: 8),
        Adam7Pass(xStart: 0, yStart: 4, xStep: 4, yStep: 8),
        Adam7Pass(xStart: 2, yStart: 0, xStep: 4, yStep: 4),
        Adam7Pass(xStart: 0, yStart: 2, xStep: 2, yStep: 4),
        Adam7Pass(xStart: 1, yStart: 0, xStep: 2, yStep: 2),
        Adam7Pass(xStart: 0, yStart: 1, xStep: 1, yStep: 2),
    ]

    private static func passExtent(_ size: Int, start: Int, step: Int) -> Int {
        size > start ? (size - start + step - 1) / step : 0
    }

    private static func scanlineByteCount(width: Int, bitsPerPixel: Int) throws(ParseError) -> Int {
        let bits = width.multipliedReportingOverflow(by: bitsPerPixel)
        guard !bits.overflow else { throw .invalidDataSize }
        return (bits.partialValue + 7) / 8
    }

    private static func deinterlace(
        _ data: [Byte],
        width: Int,
        height: Int,
        colorType: ColorType,
        bitDepth: Int
    ) throws(ParseError) -> [Byte] {
        let bitsPerPixel = colorType.channels * bitDepth
        let scanlineBytes = try scanlineByteCount(width: width, bitsPerPixel: bitsPerPixel)
        let total = height.multipliedReportingOverflow(by: scanlineBytes)
        guard !total.overflow else { throw .invalidDataSize }

        var result: [Byte] = []
        var offset = 0

        for pass in adam7Passes {
            let passWidth = passExtent(width, start: pass.xStart, step: pass.xStep)
            let passHeight = passExtent(height, start: pass.yStart, step: pass.yStep)
            guard passWidth > 0, passHeight > 0 else { continue }

            let passScanlineBytes = try scanlineByteCount(width: passWidth, bitsPerPixel: bitsPerPixel)
            let passSize = passHeight.multipliedReportingOverflow(by: passScanlineBytes + 1)
            guard !passSize.overflow, data.count - offset >= passSize.partialValue else {
                throw .invalidDataSize
            }

            if result.isEmpty {
                result = [Byte](repeating: Byte(0), count: total.partialValue)
            }

            let passPixels = try reverseFilters(
                Array(data[offset..<(offset + passSize.partialValue)]),
                width: passWidth,
                height: passHeight,
                colorType: colorType,
                bitDepth: bitDepth
            )
            offset += passSize.partialValue

            (0..<passHeight).forEach { passY in
                let targetRow = (pass.yStart + passY * pass.yStep) * scanlineBytes
                let sourceRow = passY * passScanlineBytes
                (0..<passWidth).forEach { passX in
                    copyPixel(
                        from: passPixels,
                        at: sourceRow,
                        index: passX,
                        to: &result,
                        at: targetRow,
                        index: pass.xStart + passX * pass.xStep,
                        bitsPerPixel: bitsPerPixel
                    )
                }
            }
        }

        return result
    }

    private static func copyPixel(
        from source: [Byte],
        at sourceRow: Int,
        index sourceIndex: Int,
        to target: inout [Byte],
        at targetRow: Int,
        index targetIndex: Int,
        bitsPerPixel: Int
    ) {
        if bitsPerPixel >= 8 {
            let bytesPerPixel = bitsPerPixel / 8
            let sourceStart = sourceRow + sourceIndex * bytesPerPixel
            let targetStart = targetRow + targetIndex * bytesPerPixel
            target[targetStart..<(targetStart + bytesPerPixel)] =
                source[sourceStart..<(sourceStart + bytesPerPixel)]
        } else {
            let mask = UInt8((1 << bitsPerPixel) - 1)
            let sourceBit = sourceIndex * bitsPerPixel
            let sourceShift = 8 - bitsPerPixel - sourceBit % 8
            let value = (source[sourceRow + sourceBit / 8].underlying >> sourceShift) & mask
            let targetBit = targetIndex * bitsPerPixel
            let targetShift = 8 - bitsPerPixel - targetBit % 8
            let targetByte = targetRow + targetBit / 8
            target[targetByte] = Byte(target[targetByte].underlying | (value << targetShift))
        }
    }
}

extension W3C_PNG {

    private static func readUInt32BE(_ data: [Byte], at offset: Int) -> UInt32 {
        guard let value = UInt32(bytes: data[offset..<offset + 4], endianness: .big) else {
            preconditionFailure("A four-byte slice always decodes as UInt32")
        }
        return value
    }
}
