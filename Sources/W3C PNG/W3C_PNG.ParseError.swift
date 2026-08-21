public import Byte_Primitives

extension W3C_PNG {

    public enum ParseError: Swift.Error, Sendable, Hashable {

        case invalidSignature

        case missingIHDR

        case invalidIHDR

        case unsupportedColorType(Byte)

        case unsupportedBitDepth(Int)

        case missingIDAT

        case decompressionFailed

        case invalidFilter(Byte)

        case invalidDataSize

        case missingPalette

        case invalidPalette

        case crcMismatch
    }
}
