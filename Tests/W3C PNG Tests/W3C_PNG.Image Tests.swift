import Byte
import Testing

@testable import W3C_PNG

enum `W3C_PNG.Image Tests` {}

extension `W3C_PNG.Image Tests` {
    @Suite
    struct `Image validity` {
        private static func pixels(_ count: Int) -> [Byte] {
            [Byte](repeating: Byte(0), count: count)
        }

        private static let entry = W3C_PNG.PaletteEntry(r: Byte(0), g: Byte(0), b: Byte(0))

        @Test
        func `Width and height are between one and two to the thirty-first minus one`() {
            #expect(throws: W3C_PNG.Image.Error.dimensions) {
                try W3C_PNG.Image(width: 0, height: 1, colorType: .grayscale, bitDepth: 8, rawPixels: [])
            }
            #expect(throws: W3C_PNG.Image.Error.dimensions) {
                try W3C_PNG.Image(width: 1, height: 0, colorType: .grayscale, bitDepth: 8, rawPixels: [])
            }
            #expect(throws: W3C_PNG.Image.Error.dimensions) {
                try W3C_PNG.Image(width: -1, height: 1, colorType: .grayscale, bitDepth: 8, rawPixels: [])
            }
            #expect(throws: W3C_PNG.Image.Error.dimensions) {
                try W3C_PNG.Image(width: 1 << 31, height: 1, colorType: .grayscale, bitDepth: 8, rawPixels: [])
            }
        }

        @Test
        func `A bit depth must be one the standard pairs with the color type`() {
            let invalid: [(W3C_PNG.ColorType, Int)] = [
                (.grayscale, 3), (.grayscale, 32), (.rgb, 4), (.indexed, 16), (.grayscaleAlpha, 4), (.rgba, 1), (.rgba, 0),
            ]
            for (colorType, bitDepth) in invalid {
                #expect(throws: W3C_PNG.Image.Error.bitDepth) {
                    try W3C_PNG.Image(width: 1, height: 1, colorType: colorType, bitDepth: bitDepth, rawPixels: Self.pixels(8))
                }
            }
        }

        @Test
        func `The pixels are exactly height rows of packed scanlines`() throws {
            #expect(try W3C_PNG.Image(width: 9, height: 2, colorType: .grayscale, bitDepth: 1, rawPixels: Self.pixels(4)).scanlineByteCount == 2)
            #expect(try W3C_PNG.Image(width: 3, height: 2, colorType: .rgba, bitDepth: 16, rawPixels: Self.pixels(48)).scanlineByteCount == 24)
            #expect(throws: W3C_PNG.Image.Error.pixels) {
                try W3C_PNG.Image(width: 9, height: 2, colorType: .grayscale, bitDepth: 1, rawPixels: Self.pixels(3))
            }
            #expect(throws: W3C_PNG.Image.Error.pixels) {
                try W3C_PNG.Image(width: 3, height: 2, colorType: .rgba, bitDepth: 16, rawPixels: Self.pixels(49))
            }
            #expect(throws: W3C_PNG.Image.Error.pixels) {
                try W3C_PNG.Image(width: Int(Int32.max), height: Int(Int32.max), colorType: .rgba, bitDepth: 16, rawPixels: [])
            }
        }

        @Test
        func `An indexed image needs a palette no larger than its depth can index`() throws {
            #expect(throws: W3C_PNG.Image.Error.palette) {
                try W3C_PNG.Image(width: 1, height: 1, colorType: .indexed, bitDepth: 2, rawPixels: Self.pixels(1))
            }
            #expect(throws: W3C_PNG.Image.Error.palette) {
                try W3C_PNG.Image(width: 1, height: 1, colorType: .indexed, bitDepth: 2, rawPixels: Self.pixels(1), palette: [])
            }
            #expect(throws: W3C_PNG.Image.Error.palette) {
                let palette = [W3C_PNG.PaletteEntry](repeating: Self.entry, count: 5)
                return try W3C_PNG.Image(width: 1, height: 1, colorType: .indexed, bitDepth: 2, rawPixels: Self.pixels(1), palette: palette)
            }
            let palette = [W3C_PNG.PaletteEntry](repeating: Self.entry, count: 4)
            _ = try W3C_PNG.Image(width: 1, height: 1, colorType: .indexed, bitDepth: 2, rawPixels: Self.pixels(1), palette: palette)
        }

        @Test
        func `A grayscale image has no palette and a truecolor one at most 256 entries`() throws {
            #expect(throws: W3C_PNG.Image.Error.palette) {
                try W3C_PNG.Image(width: 1, height: 1, colorType: .grayscale, bitDepth: 8, rawPixels: Self.pixels(1), palette: [Self.entry])
            }
            #expect(throws: W3C_PNG.Image.Error.palette) {
                try W3C_PNG.Image(width: 1, height: 1, colorType: .grayscaleAlpha, bitDepth: 8, rawPixels: Self.pixels(2), palette: [Self.entry])
            }
            #expect(throws: W3C_PNG.Image.Error.palette) {
                let palette = [W3C_PNG.PaletteEntry](repeating: Self.entry, count: 257)
                return try W3C_PNG.Image(width: 1, height: 1, colorType: .rgb, bitDepth: 8, rawPixels: Self.pixels(3), palette: palette)
            }
            #expect(throws: W3C_PNG.Image.Error.palette) {
                try W3C_PNG.Image(width: 1, height: 1, colorType: .rgba, bitDepth: 8, rawPixels: Self.pixels(4), palette: [])
            }
        }

        @Test
        func `A gamma of zero does not exist and the named gammas are the standard's`() {
            #expect(W3C_PNG.Gamma(scaled: 0) == nil)
            #expect(W3C_PNG.Gamma.sRGB.scaled == 45455)
            #expect(W3C_PNG.Gamma.linear.value == 1)
            #expect(W3C_PNG.Gamma(scaled: 45455) == .sRGB)
        }
    }
}

extension `W3C_PNG.Image Tests` {
    @Suite
    struct `Color chunks read` {
        private static func be32(_ value: UInt32) -> [UInt8] {
            [UInt8(value >> 24), UInt8(value >> 16 & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)]
        }

        private static func chunk(_ type: String, _ data: [UInt8]) -> [UInt8] {
            let body = Array(type.utf8) + data
            return be32(UInt32(data.count)) + body + be32(W3C_PNG.CRC.checksum(body.map(Byte.init(bitPattern:))))
        }

        private static let data: [UInt8] = [0x78, 0x01, 0x01, 0x02, 0x00, 0xFD, 0xFF, 0x00, 0x7F, 0x00, 0x81, 0x00, 0x80]

        private static func png(before: [[UInt8]] = [], after: [[UInt8]] = [], colorType: UInt8 = 0) -> [Byte] {
            let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            let header = be32(1) + be32(1) + [8, colorType, 0, 0, 0]
            let parts = [signature, chunk("IHDR", header)] + before + [chunk("IDAT", data)] + after + [chunk("IEND", [])]
            return parts.flatMap { $0 }.map(Byte.init(bitPattern:))
        }

        @Test
        func `cICP, sRGB and gAMA before the image data are read`() throws {
            let image = try W3C_PNG.parse(
                Self.png(before: [
                    Self.chunk("cICP", [9, 16, 0, 1]), Self.chunk("sRGB", [2]), Self.chunk("gAMA", Self.be32(45455)),
                ])
            )
            #expect(image.cicp == .bt2100PQ)
            #expect(image.sRGB == .saturation)
            #expect(image.gamma == .sRGB)
            #expect(image.rawPixels == [Byte(0x7F)])
        }

        @Test
        func `A file without them has none`() throws {
            let image = try W3C_PNG.parse(Self.png())
            #expect(image.cicp == nil)
            #expect(image.sRGB == nil)
            #expect(image.gamma == nil)
        }

        @Test
        func `A malformed color chunk is ignored and the image still reads`() throws {
            let malformed: [[UInt8]] = [
                Self.chunk("cICP", [9, 16, 1, 1]), Self.chunk("cICP", [9, 16, 0, 2]), Self.chunk("cICP", [9, 16, 0]),
                Self.chunk("cICP", [9, 16, 0, 1, 0]), Self.chunk("sRGB", [4]), Self.chunk("sRGB", [0, 0]), Self.chunk("sRGB", []),
                Self.chunk("gAMA", Self.be32(0)), Self.chunk("gAMA", [0, 0, 1]),
            ]
            for chunk in malformed {
                let image = try W3C_PNG.parse(Self.png(before: [chunk]))
                #expect(image.cicp == nil)
                #expect(image.sRGB == nil)
                #expect(image.gamma == nil)
                #expect(image.rawPixels == [Byte(0x7F)])
            }
        }

        @Test
        func `Color chunks after the image data are ignored and the first of a kind wins`() throws {
            let late = try W3C_PNG.parse(
                Self.png(after: [Self.chunk("cICP", [9, 16, 0, 1]), Self.chunk("sRGB", [2]), Self.chunk("gAMA", Self.be32(45455))])
            )
            #expect(late.cicp == nil)
            #expect(late.sRGB == nil)
            #expect(late.gamma == nil)
            let twice = try W3C_PNG.parse(
                Self.png(before: [
                    Self.chunk("sRGB", [1]), Self.chunk("sRGB", [3]), Self.chunk("gAMA", Self.be32(7)), Self.chunk("gAMA", Self.be32(8)),
                ])
            )
            #expect(twice.sRGB == .relativeColorimetric)
            #expect(twice.gamma == W3C_PNG.Gamma(scaled: 7))
        }

        @Test
        func `A palette on a grayscale image is an invalid palette`() {
            #expect(throws: W3C_PNG.ParseError.invalidPalette) {
                try W3C_PNG.parse(Self.png(before: [Self.chunk("PLTE", [1, 2, 3])]))
            }
        }

        @Test
        func `An indexed image with more palette entries than its depth can index is an invalid palette`() {
            let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            let header = Self.be32(1) + Self.be32(1) + [1, 3, 0, 0, 0]
            let file =
                signature + Self.chunk("IHDR", header) + Self.chunk("PLTE", [UInt8](repeating: 0, count: 9)) + Self.chunk("IDAT", Self.data)
                + Self.chunk("IEND", [])
            #expect(throws: W3C_PNG.ParseError.invalidPalette) {
                try W3C_PNG.parse(file.map(Byte.init(bitPattern:)))
            }
        }
    }
}
