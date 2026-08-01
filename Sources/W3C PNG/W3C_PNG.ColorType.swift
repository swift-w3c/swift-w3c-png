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
    }
}

extension W3C_PNG.ColorType {
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
