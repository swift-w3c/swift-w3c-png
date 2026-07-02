# swift-w3c-png

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Decodes W3C Portable Network Graphics (PNG) byte data into raw pixel data, validating the signature, parsing chunks, inflating image data via RFC 1950 (ZLIB), and reversing scanline filters.

---

## Key Features

- **Typed decode errors** — `W3C_PNG.parse` throws a typed `W3C_PNG.ParseError`, never an untyped `any Error`.
- **All five PNG color types** — grayscale, RGB, indexed, grayscale+alpha, and RGBA, exposed through `ColorType`.
- **Full bit-depth range** — 1, 2, 4, 8, and 16-bit samples, validated against the color type during IHDR parsing.
- **Scanline filter reversal** — reverses the None, Sub, Up, Average, and Paeth filters to recover raw pixel data.
- **ZLIB/DEFLATE inflation** — decompresses IDAT chunk data via RFC 1950.
- **Indexed-color palettes** — parses PLTE chunks into `PaletteEntry` values for index resolution.
- **Byte-typed pixel data** — pixels are stored as `[Byte]`, distinct from arithmetic `UInt8`.

---

## Quick Start

`parse` turns an opaque `[Byte]` stream into a decoded `Image`. The pixel layout depends on the color type: for indexed-color images, `rawPixels` holds palette indices that resolve through `palette`; for direct-color images, each pixel is `colorType.channels` bytes in scanline order.

```swift
import W3C_PNG

func describe(_ pngBytes: [Byte]) throws(W3C_PNG.ParseError) {
    let image = try W3C_PNG.parse(pngBytes)
    print("\(image.width)×\(image.height), bit depth \(image.bitDepth)")

    if image.colorType == .indexed, let palette = image.palette {
        // rawPixels holds palette indices; resolve them through `palette`.
        let entry = palette[Int(image.rawPixels[0].underlying)]
        print("Top-left color:", entry.r.underlying, entry.g.underlying, entry.b.underlying)
    } else {
        // Direct color: rawPixels is colorType.channels bytes per pixel.
        print("Bytes per pixel:", image.colorType.channels)
    }
}
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-w3c/swift-w3c-png.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "W3C PNG", package: "swift-w3c-png")
    ]
)
```

Requires Swift 6.2 or later and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
