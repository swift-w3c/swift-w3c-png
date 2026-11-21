internal import Byte
public import W3C

extension W3C.PNG.CICP {

    public enum Range: UInt8, Sendable, Hashable {

        case narrow = 0

        case full = 1
    }
}

extension W3C.PNG.CICP.Range {

    var byte: Byte {
        Byte(rawValue)
    }
}
