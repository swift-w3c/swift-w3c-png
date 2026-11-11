# swift-w3c-png

Use this package when you need the pixel data of a PNG file as bytes, or need to write pixel data as a PNG file that says what its samples mean. Start from `W3C_PNG.parse(_:)`, which gives a `W3C_PNG.Image`, and `W3C_PNG.serialize(_:filter:level:)`, which writes one. The package moves bytes and never converts samples: no palette lookup, no gamma, no change of depth.

## Laws

- What `W3C_PNG.serialize(_:filter:level:)` writes, `W3C_PNG.parse(_:)` reads back equal, for every `W3C_PNG.Image`, filter selection and compression level. The reverse does not hold: a file read and written again keeps its pixels, palette and color information, not its bytes.
- A `W3C_PNG.Image` is valid by construction, so writing one cannot fail. Its initializer refuses a width or height outside 1 to 2^31 minus 1, a bit depth the standard does not pair with the color type, `rawPixels` that are not exactly `height` rows of `scanlineByteCount` bytes, an indexed image without a palette or with more entries than its depth can index, a palette on a grayscale image, and a palette of 0 or more than 256 entries on a truecolor one. It does not check that every palette index in the pixels has an entry.
- `W3C_PNG.Image.rawPixels` holds the scanlines after decompression and unfiltering, one row after another with no filter bytes, packed at the file's bit depth and channel layout, samples of 16 bits most significant byte first. Nothing is converted: indexed images keep their palette indices, and samples below 8 bits stay packed. Adam7 interlaced files are de-interlaced into the same row order.
- Grayscale accepts bit depths 1, 2, 4, 8 and 16. RGB, grayscale with alpha and RGBA accept 8 and 16. Indexed accepts 1, 2, 4 and 8.
- The writer writes IHDR, then `cICP`, `sRGB` and `gAMA` for whichever of `cicp`, `sRGB` and `gamma` the image has, then PLTE when it has a palette, then IDAT and IEND. It never interlaces, and writes no other chunk.
- `W3C_PNG.CICP` holds the color primaries and transfer function as ITU-T H.273 code points and the range, as the Third Edition's `cICP` chunk does. The chunk's matrix coefficients are always written as 0, the only value the standard allows. Reserved code points are kept as given, so they read back.
- `W3C_PNG.Gamma.scaled` is the `gAMA` integer, gamma times 100000, and is never 0. `W3C_PNG.Gamma.sRGB` is 45455, the value the standard gives beside an `sRGB` chunk. The three color properties are independent: setting `sRGB` does not add a gamma.
- `W3C_PNG.Filter.Selection.adaptive` chooses per scanline the filter whose output has the smallest sum of absolute values, each byte read as signed, and leaves indexed images and depths under 8 unfiltered, as the standard recommends. On a tie the lower filter type wins. `fixed(_:)` uses one filter for every scanline.
- Compression is zlib through swift-rfc-1950 at the `RFC_1951.Level` given, `balanced` by default. `none` stores the data uncompressed.
- The reader uses the IHDR, PLTE, IDAT, IEND, `cICP`, `sRGB` and `gAMA` chunks. Every other chunk, including transparency and text chunks, is skipped.
- A color chunk that is malformed is ignored, and the image still reads: a wrong length, a `cICP` with matrix coefficients other than 0 or a range flag other than 0 or 1, an `sRGB` intent above 3, a `gAMA` of 0. So is one that comes after the first IDAT, or after an earlier chunk of the same type.
- Every chunk's CRC is checked, including chunks that are skipped. One wrong byte in a chunk's type, data or CRC fails the whole file with `W3C_PNG.ParseError.crcMismatch`.
- A PLTE chunk on a grayscale file, or one with more entries than an indexed file's depth can index, fails with `W3C_PNG.ParseError.invalidPalette`.
- Image data shorter than the header requires fails with `W3C_PNG.ParseError.invalidDataSize`, also for sizes that would overflow, rather than trapping.
- Reading stops at the first chunk that runs past the end of the data. A file that is cut off, or has no IEND, is read up to its last complete chunk.
