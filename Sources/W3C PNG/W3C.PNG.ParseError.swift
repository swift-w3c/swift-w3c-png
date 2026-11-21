public import Byte
public import W3C

extension W3C.PNG {

    public enum ParseError: Swift::Error, Sendable, Hashable {

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
