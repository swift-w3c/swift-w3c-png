extension W3C_PNG {

    public struct Gamma: Sendable, Hashable {

        public let scaled: UInt32

        public init?(scaled: UInt32) {
            guard scaled != 0 else { return nil }
            self.scaled = scaled
        }
    }
}

extension W3C_PNG.Gamma {

    public static let sRGB = Self(unchecked: 45455)

    public static let linear = Self(unchecked: 100_000)

    private init(unchecked scaled: UInt32) {
        self.scaled = scaled
    }

    public var value: Double {
        Double(scaled) / 100_000
    }
}
