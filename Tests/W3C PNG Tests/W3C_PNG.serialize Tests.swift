import Byte
import Testing

@testable import W3C_PNG

enum `W3C_PNG.serialize Tests` {}

extension `W3C_PNG.serialize Tests` {
    static let formats: [(W3C_PNG.ColorType, Int)] = [
        (.grayscale, 1), (.grayscale, 2), (.grayscale, 4), (.grayscale, 8), (.grayscale, 16),
        (.rgb, 8), (.rgb, 16),
        (.indexed, 1), (.indexed, 2), (.indexed, 4), (.indexed, 8),
        (.grayscaleAlpha, 8), (.grayscaleAlpha, 16),
        (.rgba, 8), (.rgba, 16),
    ]

    static let sizes: [(Int, Int)] = [(1, 1), (7, 5), (33, 17), (64, 3)]

    static let selections: [W3C_PNG.Filter.Selection] = [.adaptive] + W3C_PNG.Filter.allCases.map { .fixed($0) }

    static func image(
        _ colorType: W3C_PNG.ColorType,
        _ bitDepth: Int,
        width: Int,
        height: Int,
        seed: UInt32 = 2026
    ) throws(W3C_PNG.Image.Error) -> W3C_PNG.Image {
        let scanline = (width * colorType.channels * bitDepth + 7) / 8
        var state = seed
        var pixels: [Byte] = []
        for (row, column) in (0..<height).flatMap({ row in (0..<scanline).map { (row, $0) } }) {
            state = state &* 1_664_525 &+ 1_013_904_223
            let smooth = UInt8(truncatingIfNeeded: row * 3 + column * 5)
            let noise = UInt8(truncatingIfNeeded: state >> 24)
            pixels.append(Byte(row % 3 == 2 ? noise : smooth))
        }
        let palette: [W3C_PNG.PaletteEntry]? =
            colorType == .indexed
            ? (0..<(1 << bitDepth)).map { index in
                W3C_PNG.PaletteEntry(r: Byte(UInt8(index)), g: Byte(UInt8(255 - index)), b: Byte(UInt8(index / 2)))
            }
            : nil
        return try W3C_PNG.Image(
            width: width,
            height: height,
            colorType: colorType,
            bitDepth: bitDepth,
            rawPixels: pixels,
            palette: palette
        )
    }

    static func chunks(_ file: [Byte]) -> [(type: String, data: [UInt8])] {
        var result: [(type: String, data: [UInt8])] = []
        var offset = 8
        while offset + 12 <= file.count {
            let length = file[offset..<(offset + 4)].reduce(0) { $0 << 8 | Int($1.underlying) }
            let type = String(decoding: file[(offset + 4)..<(offset + 8)].map(\.underlying), as: UTF8.self)
            result.append((type, file[(offset + 8)..<(offset + 8 + length)].map(\.underlying)))
            offset += 12 + length
        }
        return result
    }

    static func scanlines(_ file: [Byte]) throws(RFC_1950.Error) -> [Byte] {
        let compressed = chunks(file).filter { $0.type == "IDAT" }.flatMap(\.data).map(Byte.init(_:))
        var output: [Byte] = []
        try RFC_1950.decompress(compressed, into: &output)
        return output
    }
}

extension `W3C_PNG.serialize Tests` {
    @Suite
    struct `Round trip` {
        typealias Tests = `W3C_PNG.serialize Tests`

        @Test(arguments: Tests.selections)
        func `What is written reads back equal, for every format, size and filter`(
            selection: W3C_PNG.Filter.Selection
        ) throws {
            for (colorType, bitDepth) in Tests.formats {
                for (width, height) in Tests.sizes {
                    let image = try Tests.image(colorType, bitDepth, width: width, height: height)
                    let file = W3C_PNG.serialize(image, filter: selection)
                    #expect(try W3C_PNG.parse(file) == image)
                }
            }
        }

        @Test(arguments: RFC_1951.Level.allCases)
        func `What is written reads back equal at every compression level`(level: RFC_1951.Level) throws {
            for (colorType, bitDepth) in Tests.formats {
                let image = try Tests.image(colorType, bitDepth, width: 33, height: 17)
                #expect(try W3C_PNG.parse(W3C_PNG.serialize(image, level: level)) == image)
            }
        }

        @Test
        func `Color information reads back equal in every combination`() throws {
            let cicps: [W3C_PNG.CICP?] = [nil, .sRGB, .displayP3, .bt2100PQ, .bt2100HLG, .bt709, .init(primaries: 200, transfer: 3)]
            let intents: [W3C_PNG.Intent?] = [nil] + W3C_PNG.Intent.allCases
            let gammas: [W3C_PNG.Gamma?] = [nil, .sRGB, .linear, .init(scaled: 1), .init(scaled: .max)]
            let base = try Tests.image(.rgba, 16, width: 7, height: 5)
            for cicp in cicps {
                for intent in intents {
                    for gamma in gammas {
                        let image = try W3C_PNG.Image(
                            width: base.width,
                            height: base.height,
                            colorType: base.colorType,
                            bitDepth: base.bitDepth,
                            rawPixels: base.rawPixels,
                            cicp: cicp,
                            sRGB: intent,
                            gamma: gamma
                        )
                        let read = try W3C_PNG.parse(W3C_PNG.serialize(image))
                        #expect(read == image)
                        #expect(read.cicp == cicp)
                        #expect(read.sRGB == intent)
                        #expect(read.gamma == gamma)
                    }
                }
            }
        }

        @Test
        func `A suggested palette on a truecolor image reads back equal`() throws {
            let base = try Tests.image(.rgb, 8, width: 7, height: 5)
            let palette = [W3C_PNG.PaletteEntry(r: Byte(1), g: Byte(2), b: Byte(3)), .init(r: Byte(255), g: Byte(0), b: Byte(128))]
            let image = try W3C_PNG.Image(width: 7, height: 5, colorType: .rgb, bitDepth: 8, rawPixels: base.rawPixels, palette: palette)
            #expect(try W3C_PNG.parse(W3C_PNG.serialize(image)) == image)
        }

        @Test
        func `Serializing into a collection appends to it`() throws {
            let image = try Tests.image(.grayscale, 8, width: 7, height: 5)
            var output: [Byte] = [Byte(0xAA)]
            W3C_PNG.serialize(image, into: &output)
            #expect(output.first == Byte(0xAA))
            #expect(Array(output.dropFirst()) == W3C_PNG.serialize(image))
        }
    }
}

extension `W3C_PNG.serialize Tests` {
    @Suite
    struct `File layout` {
        typealias Tests = `W3C_PNG.serialize Tests`

        @Test
        func `A one pixel grayscale image stored without compression is this exact file`() throws {
            let image = try W3C_PNG.Image(width: 1, height: 1, colorType: .grayscale, bitDepth: 8, rawPixels: [Byte(0x7F)])
            let expected: [UInt8] = [
                0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
                0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
                0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x00, 0x00, 0x00, 0x00,
                0x3A, 0x7E, 0x9B, 0x55,
                0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54,
                0x78, 0x01, 0x01, 0x02, 0x00, 0xFD, 0xFF, 0x00, 0x7F, 0x00, 0x81, 0x00, 0x80,
                0x7C, 0x4B, 0x6C, 0xA3,
                0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
                0xAE, 0x42, 0x60, 0x82,
            ]
            #expect(W3C_PNG.serialize(image, filter: .fixed(.none), level: .none).map(\.underlying) == expected)
        }

        @Test
        func `Chunks come in the standard's order, color information before the palette and the data`() throws {
            let base = try Tests.image(.indexed, 8, width: 7, height: 5)
            let image = try W3C_PNG.Image(
                width: 7,
                height: 5,
                colorType: .indexed,
                bitDepth: 8,
                rawPixels: base.rawPixels,
                palette: base.palette,
                cicp: .displayP3,
                sRGB: .relativeColorimetric,
                gamma: .sRGB
            )
            let chunks = Tests.chunks(W3C_PNG.serialize(image))
            #expect(chunks.map(\.type) == ["IHDR", "cICP", "sRGB", "gAMA", "PLTE", "IDAT", "IEND"])
            #expect(chunks[0].data == [0, 0, 0, 7, 0, 0, 0, 5, 8, 3, 0, 0, 0])
            #expect(chunks[1].data == [0x0C, 0x0D, 0x00, 0x01])
            #expect(chunks[2].data == [1])
            #expect(chunks[3].data == [0x00, 0x00, 0xB1, 0x8F])
            #expect(chunks[4].data.count == 768)
            #expect(Array(chunks[4].data.prefix(6)) == [0, 255, 0, 1, 254, 0])
            #expect(chunks[6].data.isEmpty)
        }

        @Test
        func `The standard's own cICP examples are written byte for byte`() throws {
            let base = try Tests.image(.rgb, 8, width: 1, height: 1)
            let expected: [(W3C_PNG.CICP, [UInt8])] = [
                (.bt2100PQ, [0x09, 0x10, 0x00, 0x01]), (.bt2100HLG, [0x09, 0x12, 0x00, 0x01]),
                (.bt709, [0x01, 0x01, 0x00, 0x00]), (.displayP3, [0x0C, 0x0D, 0x00, 0x01]),
            ]
            for (cicp, bytes) in expected {
                let image = try W3C_PNG.Image(width: 1, height: 1, colorType: .rgb, bitDepth: 8, rawPixels: base.rawPixels, cicp: cicp)
                #expect(Tests.chunks(W3C_PNG.serialize(image)).first { $0.type == "cICP" }?.data == bytes)
            }
        }

        @Test(arguments: W3C_PNG.Filter.allCases)
        func `A fixed filter is the filter of every scanline`(filter: W3C_PNG.Filter) throws {
            let image = try Tests.image(.rgb, 8, width: 7, height: 5)
            let scanlines = try Tests.scanlines(W3C_PNG.serialize(image, filter: .fixed(filter)))
            #expect(scanlines.count == 5 * 22)
            #expect(stride(from: 0, to: 110, by: 22).allSatisfy { scanlines[$0].underlying == filter.rawValue })
        }

        @Test
        func `The adaptive filter takes the smallest sum of absolute differences`() throws {
            let row: [UInt8] = (0..<16).map { UInt8($0 * 10) }
            let pixels = (row + row + row.map { $0 &+ 1 }).map(Byte.init(_:))
            let image = try W3C_PNG.Image(width: 16, height: 3, colorType: .grayscale, bitDepth: 8, rawPixels: pixels)
            let scanlines = try Tests.scanlines(W3C_PNG.serialize(image))
            #expect(scanlines[0].underlying == W3C_PNG.Filter.sub.rawValue)
            #expect(scanlines[17].underlying == W3C_PNG.Filter.up.rawValue)
            #expect(scanlines[18..<34].allSatisfy { $0.underlying == 0 })
            #expect(scanlines[34].underlying == W3C_PNG.Filter.up.rawValue)
            #expect(scanlines[35..<51].allSatisfy { $0.underlying == 1 })
        }

        @Test
        func `The adaptive filter leaves indexed images and depths under eight unfiltered`() throws {
            for (colorType, bitDepth) in Tests.formats where colorType == .indexed || bitDepth < 8 {
                let image = try Tests.image(colorType, bitDepth, width: 33, height: 17)
                let scanlines = try Tests.scanlines(W3C_PNG.serialize(image))
                let stride = image.scanlineByteCount + 1
                #expect(Swift.stride(from: 0, to: 17 * stride, by: stride).allSatisfy { scanlines[$0].underlying == 0 })
            }
        }

        @Test
        func `Every chunk carries the CRC of its type and data`() throws {
            let file = W3C_PNG.serialize(try Tests.image(.rgba, 8, width: 33, height: 17))
            var offset = 8
            var count = 0
            while offset < file.count {
                let length = file[offset..<(offset + 4)].reduce(0) { $0 << 8 | Int($1.underlying) }
                let end = offset + 8 + length
                let stored = file[end..<(end + 4)].reduce(UInt32(0)) { $0 << 8 | UInt32($1.underlying) }
                #expect(W3C_PNG.CRC.checksum(file[(offset + 4)..<end]) == stored)
                offset = end + 4
                count += 1
            }
            #expect(offset == file.count)
            #expect(count == 3)
        }
    }
}
