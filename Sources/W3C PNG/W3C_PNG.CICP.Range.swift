internal import Byte

extension W3C_PNG.CICP {

    public enum Range: UInt8, Sendable, Hashable {

        case narrow = 0

        case full = 1
    }
}

extension W3C_PNG.CICP.Range {

    var byte: Byte {
        Byte(rawValue)
    }
}
