import Byte
import Testing

@testable import W3C_PNG

@Suite
struct `PNG 3rd edition §5.3 chunk CRC` {
    private static let valid: [UInt8] = [
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

    private static func flipping(_ index: Int) -> [Byte] {
        var bytes = valid
        bytes[index] ^= 0x01
        return bytes.map(Byte.init(bitPattern:))
    }

    @Test
    func `the Annex D CRC of the ASCII digits one to nine is CBF43926`() {
        #expect(W3C_PNG.CRC.checksum(Array("123456789".utf8).map(Byte.init(bitPattern:))) == 0xCBF4_3926)
    }

    @Test
    func `a PNG with correct chunk CRCs decodes`() throws {
        let image = try W3C_PNG.parse(Self.valid.map(Byte.init(bitPattern:)))
        #expect(image.rawPixels == [Byte(bitPattern: 0x7F)])
    }

    @Test(arguments: [29, 32, 54, 57, 66, 69])
    func `a flipped CRC byte throws crcMismatch`(index: Int) {
        #expect(throws: W3C_PNG.ParseError.crcMismatch) { try W3C_PNG.parse(Self.flipping(index)) }
    }

    @Test(arguments: [12, 20, 37, 49, 62])
    func `a flipped chunk type or data byte throws crcMismatch`(index: Int) {
        #expect(throws: W3C_PNG.ParseError.crcMismatch) { try W3C_PNG.parse(Self.flipping(index)) }
    }
}
