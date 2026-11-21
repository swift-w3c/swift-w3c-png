public import W3C

extension W3C.PNG.Filter {

    public enum Selection: Sendable, Hashable {

        case adaptive

        case fixed(W3C.PNG.Filter)
    }
}
