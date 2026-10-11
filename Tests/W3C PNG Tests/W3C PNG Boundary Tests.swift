import Byte
import Testing

@testable import W3C_PNG

@Suite
struct `PNG header boundaries` {
    private static func be32(_ value: UInt32) -> [UInt8] {
        [UInt8(value >> 24), UInt8(value >> 16 & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value & 0xFF)]
    }

    private static func chunk(_ type: String, _ data: [UInt8]) -> [UInt8] {
        let body = Array(type.utf8) + data
        return be32(UInt32(data.count)) + body + be32(W3C_PNG.CRC.checksum(body.map(Byte.init(bitPattern:))))
    }

    private static func png(width: UInt32, height: UInt32, bitDepth: UInt8 = 8, colorType: UInt8 = 0) -> [Byte] {
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let header = be32(width) + be32(height) + [bitDepth, colorType, 0, 0, 0]
        let idat: [UInt8] = [0x78, 0x01, 0x01, 0x02, 0x00, 0xFD, 0xFF, 0x00, 0x7F, 0x00, 0x81, 0x00, 0x80]
        return (signature + chunk("IHDR", header) + chunk("IDAT", idat) + chunk("IEND", []))
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
    func `the largest valid dimensions with too little data throw instead of trapping`() {
        #expect(throws: W3C_PNG.ParseError.invalidDataSize) {
            try W3C_PNG.parse(Self.png(width: 0x7FFF_FFFF, height: 0x7FFF_FFFF, bitDepth: 16, colorType: 6))
        }
    }
}
