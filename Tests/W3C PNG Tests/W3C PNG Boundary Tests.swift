import Byte
import Testing

@testable import W3C_PNG

enum `W3C PNG Boundary Tests` {}

extension `W3C PNG Boundary Tests` {
    @Suite
    struct `PNG header boundaries` {
        private static func be32(_ value: UInt32) -> [UInt8] {
            [UInt8(value >> 24), UInt8(value >> 16 & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)]
        }

        private static func chunk(_ type: String, _ data: [UInt8]) -> [UInt8] {
            let body = Array(type.utf8) + data
            return be32(UInt32(data.count)) + body + be32(W3C_PNG.CRC.checksum(body.map(Byte.init(bitPattern:))))
        }

        private static func zlibStored(_ data: [UInt8]) -> [UInt8] {
            var a: UInt32 = 1
            var b: UInt32 = 0
            for byte in data {
                a = (a + UInt32(byte)) % 65521
                b = (b + a) % 65521
            }
            let length = UInt16(data.count)
            return [0x78, 0x01, 0x01, UInt8(length & 0xFF), UInt8(length >> 8), UInt8(~length & 0xFF), UInt8(~length >> 8)]
                + data + be32(b << 16 | a)
        }

        private static func png(
            width: UInt32,
            height: UInt32,
            bitDepth: UInt8 = 8,
            colorType: UInt8 = 0,
            compressionMethod: UInt8 = 0,
            filterMethod: UInt8 = 0,
            interlaceMethod: UInt8 = 0,
            scanlines: [UInt8] = [0x00, 0x7F]
        ) -> [Byte] {
            let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            let header =
                be32(width) + be32(height) + [bitDepth, colorType, compressionMethod, filterMethod, interlaceMethod]
            return (signature + chunk("IHDR", header) + chunk("IDAT", zlibStored(scanlines)) + chunk("IEND", []))
                .map(Byte.init(bitPattern:))
        }

        @Test
        func `a one pixel grayscale image decodes`() throws {
            let image = try W3C_PNG.parse(Self.png(width: 1, height: 1))
            #expect(image.width == 1)
            #expect(image.height == 1)
            #expect(image.rawPixels == [Byte(bitPattern: 0x7F)])
        }

        @Test
        func `zero width or height is an invalid header`() {
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) { try W3C_PNG.parse(Self.png(width: 0, height: 1)) }
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) { try W3C_PNG.parse(Self.png(width: 1, height: 0)) }
        }

        @Test
        func `dimensions above two to the thirty-first minus one are an invalid header`() {
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) { try W3C_PNG.parse(Self.png(width: 0x8000_0000, height: 1)) }
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) { try W3C_PNG.parse(Self.png(width: 1, height: 0xFFFF_FFFF)) }
        }

        @Test
        func `a compression or filter method other than zero is an invalid header`() {
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) {
                try W3C_PNG.parse(Self.png(width: 1, height: 1, compressionMethod: 1))
            }
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) {
                try W3C_PNG.parse(Self.png(width: 1, height: 1, filterMethod: 1))
            }
        }

        @Test
        func `an interlace method other than none or Adam7 is an invalid header`() {
            #expect(throws: W3C_PNG.ParseError.invalidIHDR) {
                try W3C_PNG.parse(Self.png(width: 1, height: 1, interlaceMethod: 2))
            }
        }

        @Test
        func `an Adam7 interlaced image decodes to its pixels in row order`() throws {
            let passes: [UInt8] = [
                0x00, 1,
                0x00, 3,
                0x00, 7, 9,
                0x00, 2,
                0x00, 8,
                0x00, 4, 5, 6,
            ]
            let image = try W3C_PNG.parse(Self.png(width: 3, height: 3, interlaceMethod: 1, scanlines: passes))
            #expect(image.rawPixels == (1...9).map { Byte(bitPattern: $0) })
        }

        @Test
        func `an Adam7 interlaced one bit image packs its pixels into rows`() throws {
            let passes: [UInt8] = [
                0x00, 0x80,
                0x00, 0x00,
                0x00, 0xC0,
            ]
            let image = try W3C_PNG.parse(
                Self.png(width: 2, height: 2, bitDepth: 1, interlaceMethod: 1, scanlines: passes)
            )
            #expect(image.rawPixels == [Byte(bitPattern: 0x80), Byte(bitPattern: 0xC0)])
        }

        @Test
        func `an Adam7 interlaced image with a missing pass is too short`() {
            #expect(throws: W3C_PNG.ParseError.invalidDataSize) {
                try W3C_PNG.parse(Self.png(width: 3, height: 3, interlaceMethod: 1, scanlines: [0x00, 1, 0x00, 3]))
            }
        }

        @Test
        func `the largest valid dimensions with too little data throw instead of trapping`() {
            #expect(throws: W3C_PNG.ParseError.invalidDataSize) {
                try W3C_PNG.parse(Self.png(width: 0x7FFF_FFFF, height: 0x7FFF_FFFF, bitDepth: 16, colorType: 6))
            }
        }
    }
}
