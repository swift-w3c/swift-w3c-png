internal import Byte
public import W3C

extension W3C.PNG {

    public enum Intent: UInt8, Sendable, Hashable, CaseIterable {

        case perceptual = 0

        case relativeColorimetric = 1

        case saturation = 2

        case absoluteColorimetric = 3
    }
}

extension W3C.PNG.Intent {

    var byte: Byte {
        Byte(rawValue)
    }
}
