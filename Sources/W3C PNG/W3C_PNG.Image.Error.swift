extension W3C_PNG.Image {

    public enum Error: Swift::Error, Sendable, Hashable {

        case dimensions

        case bitDepth

        case pixels

        case palette
    }
}
