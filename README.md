# swift-w3c-png

Use this package when you need the pixel data of a PNG file as bytes, for example to embed it elsewhere or convert it yourself. Start from `W3C_PNG.parse(_:)`, which gives a `W3C_PNG.Image`. It reads PNG files only and does not write them.

## Laws

- `W3C_PNG.Image.rawPixels` holds the scanlines after decompression and unfiltering, one row after another with no filter bytes, packed at the file's bit depth and channel layout. Nothing is converted: indexed images keep their palette indices, and samples below 8 bits stay packed. Adam7 interlaced files are de-interlaced into the same row order.
- Only the IHDR, PLTE, IDAT and IEND chunks are used. Every other chunk, including transparency, gamma and text chunks, is skipped.
- Every chunk's CRC is checked, including chunks that are skipped. One wrong byte in a chunk's type, data or CRC fails the whole file with `W3C_PNG.ParseError.crcMismatch`.
- Width and height must each be between 1 and 2^31 minus 1.
- Grayscale accepts bit depths 1, 2, 4, 8 and 16. RGB, grayscale with alpha and RGBA accept 8 and 16. Indexed accepts 1, 2, 4 and 8, and needs a PLTE chunk of 1 to 256 entries.
- Image data shorter than the header requires fails with `W3C_PNG.ParseError.invalidDataSize`, also for sizes that would overflow, rather than trapping.
- Reading stops at the first chunk that runs past the end of the data. A file that is cut off, or has no IEND, is read up to its last complete chunk.
