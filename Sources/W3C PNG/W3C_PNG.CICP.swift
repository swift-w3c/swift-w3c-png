extension W3C_PNG {

    public struct CICP: Sendable, Hashable {

        public var primaries: UInt8

        public var transfer: UInt8

        public var range: Range

        public init(primaries: UInt8, transfer: UInt8, range: Range = .full) {
            self.primaries = primaries
            self.transfer = transfer
            self.range = range
        }
    }
}

extension W3C_PNG.CICP {

    public static let sRGB = Self(primaries: 1, transfer: 13)

    public static let displayP3 = Self(primaries: 12, transfer: 13)

    public static let bt2100PQ = Self(primaries: 9, transfer: 16)

    public static let bt2100HLG = Self(primaries: 9, transfer: 18)

    public static let bt709 = Self(primaries: 1, transfer: 1, range: .narrow)
}
