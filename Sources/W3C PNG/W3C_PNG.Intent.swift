internal import Byte

extension W3C_PNG {

    public enum Intent: UInt8, Sendable, Hashable, CaseIterable {

        case perceptual = 0

        case relativeColorimetric = 1

        case saturation = 2

        case absoluteColorimetric = 3
    }
}

extension W3C_PNG.Intent {

    var byte: Byte {
        Byte(rawValue)
    }
}
