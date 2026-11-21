public import Byte
public import W3C

extension W3C.PNG {

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
