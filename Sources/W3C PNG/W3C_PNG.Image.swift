// W3C_PNG.Image.swift

public import Byte_Primitives

extension W3C_PNG {
    /// A decoded PNG image
    ///
    /// Contains the raw pixel data after decompression and filter reversal.
    /// Pixel data is stored in scanline order, top-to-bottom, left-to-right.
    ///
    /// ## Pixel Format
    ///
    /// The format of `rawPixels` depends on `colorType`:
    /// - Grayscale: 1 byte per pixel (gray)
    /// - RGB: 3 bytes per pixel (R, G, B)
    /// - Indexed: 1 byte per pixel (palette index)
    /// - Grayscale + Alpha: 2 bytes per pixel (gray, alpha)
    /// - RGBA: 4 bytes per pixel (R, G, B, A)
    public struct Image: Sendable, Hashable {
        /// Image width in pixels
        public let width: Int

        /// Image height in pixels
        public let height: Int

        /// Color type
        public let colorType: ColorType

        /// Bit depth (1, 2, 4, 8, or 16)
        public let bitDepth: Int

        /// Decompressed, defiltered pixel data
        ///
        /// For indexed-color images, this contains palette indices.
        /// Use `palette` to map indices to RGB colors.
        public let rawPixels: [Byte]

        /// Color palette for indexed-color images
        ///
        /// Each entry is an RGB color. Only present for `colorType == .indexed`.
        public let palette: [PaletteEntry]?

        /// Create an image
        public init(
            width: Int,
            height: Int,
            colorType: ColorType,
            bitDepth: Int,
            rawPixels: [Byte],
            palette: [PaletteEntry]? = nil
        ) {
            self.width = width
            self.height = height
            self.colorType = colorType
            self.bitDepth = bitDepth
            self.rawPixels = rawPixels
            self.palette = palette
        }
    }
}

extension W3C_PNG {
    /// A single palette entry (RGB color)
    public struct PaletteEntry: Sendable, Hashable {
        public let r: Byte
        public let g: Byte
        public let b: Byte

        public init(r: Byte, g: Byte, b: Byte) {
            self.r = r
            self.g = g
            self.b = b
        }
    }
}

extension W3C_PNG {
    /// PNG color type (IHDR color type field)
    ///
    /// Defines how pixel data is interpreted.
    public enum ColorType: UInt8, Sendable, Hashable {
        /// Grayscale (1 sample per pixel)
        case grayscale = 0

        /// RGB truecolor (3 samples per pixel)
        case rgb = 2

        /// Indexed-color (1 palette index per pixel)
        case indexed = 3

        /// Grayscale with alpha (2 samples per pixel)
        case grayscaleAlpha = 4

        /// RGBA truecolor with alpha (4 samples per pixel)
        case rgba = 6

        /// Number of channels for this color type
        public var channels: Int {
            switch self {
            case .grayscale: 1
            case .rgb: 3
            case .indexed: 1
            case .grayscaleAlpha: 2
            case .rgba: 4
            }
        }
    }
}

extension W3C_PNG {
    /// PNG parsing errors
    public enum ParseError: Error, Sendable, Hashable {
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
