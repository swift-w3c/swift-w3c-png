// W3C_PNG.swift

/// W3C PNG: Portable Network Graphics (Second Edition)
///
/// PNG is a lossless image format that supports:
/// - Grayscale, RGB, and indexed-color images
/// - Alpha transparency
/// - Lossless compression using DEFLATE (RFC 1951)
///
/// ## Key Types
///
/// - ``Image``: Decoded PNG image with raw pixel data
/// - ``ColorType``: Image color type, such as grayscale or RGB
///
/// ## Example
///
/// ```swift
/// // Parse PNG data
/// let image = try W3C_PNG.parse(pngBytes)
/// print("Size: \(image.width)x\(image.height)")
/// print("Pixels: \(image.rawPixels.count) bytes")
/// ```
///
/// ## See Also
///
/// - [W3C PNG Specification (Second Edition)](https://www.w3.org/TR/PNG/)
/// - [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950) - ZLIB wrapper
/// - [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951) - DEFLATE compression
public enum W3C_PNG {}
