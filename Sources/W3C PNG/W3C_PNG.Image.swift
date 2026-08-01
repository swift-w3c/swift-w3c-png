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

