internal import Byte
public import W3C

extension W3C.PNG {

    public enum ColorType: UInt8, Sendable, Hashable {

        case grayscale = 0

        case rgb = 2

        case indexed = 3

        case grayscaleAlpha = 4

        case rgba = 6
    }
}

extension W3C.PNG.ColorType {

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

extension W3C.PNG.ColorType {

    var bitDepths: [Int] {
        switch self {
        case .grayscale: [1, 2, 4, 8, 16]
        case .rgb, .grayscaleAlpha, .rgba: [8, 16]
        case .indexed: [1, 2, 4, 8]
        }
    }
}

extension W3C.PNG.ColorType {

    var byte: Byte {
        Byte(rawValue)
    }
}
