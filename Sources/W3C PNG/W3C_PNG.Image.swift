public import Byte

extension W3C_PNG {

    public struct Image: Sendable, Hashable {

        public let width: Int

        public let height: Int

        public let colorType: ColorType

        public let bitDepth: Int

        public let rawPixels: [Byte]

        public let palette: [PaletteEntry]?

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
