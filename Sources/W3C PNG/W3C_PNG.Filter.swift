internal import Byte

extension W3C_PNG {

    public enum Filter: UInt8, Sendable, Hashable, CaseIterable {

        case none = 0

        case sub = 1

        case up = 2

        case average = 3

        case paeth = 4
    }
}

extension W3C_PNG.Filter {

    static func predictor(_ a: Int, _ b: Int, _ c: Int) -> Int {
        let p = a + b - c
        let pa = abs(p - a)
        let pb = abs(p - b)
        let pc = abs(p - c)

        return if pa <= pb && pa <= pc {
            a
        } else if pb <= pc {
            b
        } else {
            c
        }
    }

    func prediction(left a: UInt8, above b: UInt8, aboveLeft c: UInt8) -> UInt8 {
        switch self {
        case .none: 0
        case .sub: a
        case .up: b
        case .average: UInt8((Int(a) + Int(b)) / 2)
        case .paeth: UInt8(Self.predictor(Int(a), Int(b), Int(c)))
        }
    }

    func apply(to scanline: ArraySlice<Byte>, previous: ArraySlice<Byte>?, bytesPerPixel: Int, into output: inout [Byte]) {
        for (offset, byte) in scanline.enumerated() {
            let hasLeft = offset >= bytesPerPixel
            let left = hasLeft ? scanline[scanline.startIndex + offset - bytesPerPixel].underlying : 0
            let above = previous.map { $0[$0.startIndex + offset].underlying } ?? 0
            let aboveLeft = hasLeft ? previous.map { $0[$0.startIndex + offset - bytesPerPixel].underlying } ?? 0 : 0
            output.append(Byte(byte.underlying &- prediction(left: left, above: above, aboveLeft: aboveLeft)))
        }
    }
}

extension W3C_PNG.Filter {

    var byte: Byte {
        Byte(rawValue)
    }
}
