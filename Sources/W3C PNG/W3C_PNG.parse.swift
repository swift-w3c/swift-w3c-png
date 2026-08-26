internal import Binary_Endianness_Primitives
internal import Binary_Standard_Library_Integration
public import Byte
internal import Byte_Standard_Library_Integration

extension W3C_PNG {

    private static let signature: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

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

        let rawPixels = try reverseFilters(
            decompressed,
            width: header.width,
            height: header.height,
            colorType: header.colorType,
            bitDepth: header.bitDepth
        )

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
    }

    private static func parseIHDR(_ data: [Byte]) throws(ParseError) -> IHDR {
        guard data.count >= 13 else {
            throw .invalidIHDR
        }

        let width = Int(readUInt32BE(data, at: 0))
        let height = Int(readUInt32BE(data, at: 4))
        let bitDepth = Int(data[8])
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

        return IHDR(
            width: width,
            height: height,
            bitDepth: bitDepth,
            colorType: colorType
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
        let scanlineBytes = (width * bitsPerPixel + 7) / 8
        let scanlineWithFilter = scanlineBytes + 1

        guard data.count >= height * scanlineWithFilter else {
            throw .invalidDataSize
        }

        var result: [Byte] = []
        result.reserveCapacity(height * scanlineBytes)

        var previousScanline: [Byte] = Array(repeating: 0, count: scanlineBytes)

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
                let a = i >= bytesPerPixel ? Int(result[i - bytesPerPixel]) : 0
                let b = Int(previous[i])
                result[i] = Byte(result[i].underlying &+ UInt8((a + b) / 2))
            }

        case .paeth:
            result.indices.forEach { i in
                let a = i >= bytesPerPixel ? Int(result[i - bytesPerPixel]) : 0
                let b = Int(previous[i])
                let c = i >= bytesPerPixel ? Int(previous[i - bytesPerPixel]) : 0
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

        if pa <= pb && pa <= pc {
            return a
        } else if pb <= pc {
            return b
        } else {
            return c
        }
    }
}

extension W3C_PNG {

    private static func readUInt32BE(_ data: [Byte], at offset: Int) -> UInt32 {
        UInt32(bytes: data[offset..<offset + 4], endianness: .big)!
    }
}
