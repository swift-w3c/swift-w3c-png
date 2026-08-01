public import Byte_Primitives

extension W3C_PNG {
    /// PNG parsing errors
    public enum ParseError: Swift.Error, Sendable, Hashable {
        /// Invalid PNG signature (not 89 50 4E 47 0D 0A 1A 0A)
        case invalidSignature

        /// Missing required IHDR chunk
        case missingIHDR

        /// Invalid IHDR chunk data
        case invalidIHDR

        /// Unsupported color type
        case unsupportedColorType(Byte)

        /// Unsupported bit depth for color type
        case unsupportedBitDepth(Int)

        /// Missing IDAT chunks (no image data)
        case missingIDAT

        /// ZLIB decompression failed
        case decompressionFailed

        /// Invalid filter type in scanline
        case invalidFilter(Byte)

        /// Image data does not match expected size
        case invalidDataSize

        /// Missing palette for indexed-color image
        case missingPalette

        /// Invalid palette chunk
        case invalidPalette

        /// CRC checksum mismatch
        case crcMismatch
    }
}
