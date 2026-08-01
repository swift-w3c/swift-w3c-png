// W3C_PNG_Tests.swift

import Byte_Primitives
import Testing

@testable import W3C_PNG

@Suite("W3C PNG Parsing")
struct W3C_PNG_Tests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}

    @Test
    func `invalid signature throws error`() throws {
        let invalidData: [Byte] = [0x00, 0x00, 0x00, 0x00]
        #expect(throws: W3C_PNG.ParseError.invalidSignature) {
            try W3C_PNG.parse(invalidData)
        }
    }

    @Test
    func `missing IHDR throws error`() throws {
        // Valid signature but no IHDR
        let data: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        #expect(throws: W3C_PNG.ParseError.missingIHDR) {
            try W3C_PNG.parse(data)
        }
    }

    @Test
    func `color type channels`() {
        #expect(W3C_PNG.ColorType.grayscale.channels == 1)
        #expect(W3C_PNG.ColorType.rgb.channels == 3)
        #expect(W3C_PNG.ColorType.indexed.channels == 1)
        #expect(W3C_PNG.ColorType.grayscaleAlpha.channels == 2)
        #expect(W3C_PNG.ColorType.rgba.channels == 4)
    }
}
