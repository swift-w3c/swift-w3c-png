extension W3C_PNG {

    enum FilterType: UInt8 {
        case none = 0
        case sub = 1
        case up = 2
        case average = 3
        case paeth = 4
    }
}
