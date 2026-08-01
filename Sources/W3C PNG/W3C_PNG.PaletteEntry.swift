public import Byte_Primitives

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
