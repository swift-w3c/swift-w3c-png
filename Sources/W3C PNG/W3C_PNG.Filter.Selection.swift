extension W3C_PNG.Filter {

    public enum Selection: Sendable, Hashable {

        case adaptive

        case fixed(W3C_PNG.Filter)
    }
}
