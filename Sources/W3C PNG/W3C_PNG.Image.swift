public import Byte

extension W3C_PNG {

    public struct Image: Sendable, Hashable {

        public let width: Int

        public let height: Int

        public let colorType: ColorType

        public let bitDepth: Int

        public let rawPixels: [Byte]

        public let palette: [PaletteEntry]?

        public let cicp: CICP?

        public let sRGB: Intent?

        public let gamma: Gamma?

        public init(
            width: Int,
            height: Int,
            colorType: ColorType,
            bitDepth: Int,
            rawPixels: [Byte],
            palette: [PaletteEntry]? = nil,
            cicp: CICP? = nil,
            sRGB: Intent? = nil,
            gamma: Gamma? = nil
        ) throws(Error) {
            guard (1...Int(Int32.max)).contains(width), (1...Int(Int32.max)).contains(height) else {
                throw .dimensions
            }
            guard colorType.bitDepths.contains(bitDepth) else {
                throw .bitDepth
            }
            guard let scanline = Self.scanlineByteCount(width: width, colorType: colorType, bitDepth: bitDepth) else {
                throw .pixels
            }
            let required = height.multipliedReportingOverflow(by: scanline)
            guard !required.overflow, rawPixels.count == required.partialValue else {
                throw .pixels
            }
            switch colorType {
            case .grayscale, .grayscaleAlpha:
                guard palette == nil else { throw .palette }

            case .rgb, .rgba:
                guard palette.map({ (1...256).contains($0.count) }) ?? true else { throw .palette }

            case .indexed:
                guard let palette, (1...(1 << bitDepth)).contains(palette.count) else { throw .palette }
            }
            self.width = width
            self.height = height
            self.colorType = colorType
            self.bitDepth = bitDepth
            self.rawPixels = rawPixels
            self.palette = palette
            self.cicp = cicp
            self.sRGB = sRGB
            self.gamma = gamma
        }
    }
}

extension W3C_PNG.Image {

    static func scanlineByteCount(width: Int, colorType: W3C_PNG.ColorType, bitDepth: Int) -> Int? {
        let bits = width.multipliedReportingOverflow(by: colorType.channels * bitDepth)
        guard !bits.overflow, bits.partialValue <= Int.max - 7 else { return nil }
        return (bits.partialValue + 7) / 8
    }

    public var scanlineByteCount: Int {
        rawPixels.count / height
    }
}
