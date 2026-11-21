public import W3C

extension W3C.PNG.Image {

    public enum Error: Swift::Error, Sendable, Hashable {

        case dimensions

        case bitDepth

        case pixels

        case palette
    }
}
