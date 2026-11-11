internal import Binary
public import Byte
public import RFC_1950

extension W3C_PNG {

    public static func serialize<Output>(
        _ image: Image,
        into output: inout Output,
        filter: Filter.Selection = .adaptive,
        level: RFC_1951.Level = .balanced
    ) where Output: RangeReplaceableCollection, Output.Element == Byte {
        output.append(contentsOf: signature)

        var header: [Byte] = []
        UInt32(image.width).bytes(into: &header, endianness: .big)
        UInt32(image.height).bytes(into: &header, endianness: .big)
        header.append(Byte(UInt8(image.bitDepth)))
        header.append(image.colorType.byte)
        header.append(contentsOf: [Byte(0), Byte(0), Byte(0)])
        append(chunk: "IHDR", header, to: &output)

        if let cicp = image.cicp {
            append(chunk: "cICP", [Byte(cicp.primaries), Byte(cicp.transfer), Byte(0), cicp.range.byte], to: &output)
        }
        if let intent = image.sRGB {
            append(chunk: "sRGB", [intent.byte], to: &output)
        }
        if let gamma = image.gamma {
            append(chunk: "gAMA", gamma.scaled.bytes(endianness: .big), to: &output)
        }
        if let palette = image.palette {
            append(chunk: "PLTE", palette.flatMap { [$0.r, $0.g, $0.b] }, to: &output)
        }

        let compressed = RFC_1950.compress(filtered(image, filter), level: level)
        var start = compressed.startIndex
        repeat {
            let end = compressed.index(start, offsetBy: chunkLengthLimit, limitedBy: compressed.endIndex) ?? compressed.endIndex
            append(chunk: "IDAT", compressed[start..<end], to: &output)
            start = end
        } while start < compressed.endIndex

        append(chunk: "IEND", [], to: &output)
    }

    public static func serialize(
        _ image: Image,
        filter: Filter.Selection = .adaptive,
        level: RFC_1951.Level = .balanced
    ) -> [Byte] {
        var output: [Byte] = []
        serialize(image, into: &output, filter: filter, level: level)
        return output
    }
}

extension W3C_PNG {

    static let signature: [Byte] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].map(Byte.init(bitPattern:))

    static let chunkLengthLimit = Int(Int32.max)

    private static func append<Output>(
        chunk type: String,
        _ data: some Swift::Collection<Byte>,
        to output: inout Output
    ) where Output: RangeReplaceableCollection, Output.Element == Byte {
        var body: [Byte] = type.utf8.map(Byte.init(bitPattern:))
        body.append(contentsOf: data)
        UInt32(data.count).bytes(into: &output, endianness: .big)
        output.append(contentsOf: body)
        CRC.checksum(body).bytes(into: &output, endianness: .big)
    }

    private static func filtered(_ image: Image, _ selection: Filter.Selection) -> [Byte] {
        let scanline = image.scanlineByteCount
        let bitsPerPixel = image.colorType.channels * image.bitDepth
        let bytesPerPixel = (bitsPerPixel + 7) / 8
        let candidates: [Filter] =
            switch selection {
            case .fixed(let filter): [filter]
            case .adaptive: image.colorType == .indexed || image.bitDepth < 8 ? [.none] : Filter.allCases
            }

        var result: [Byte] = []
        result.reserveCapacity(image.rawPixels.count + image.height)
        var best: [Byte] = []
        var attempt: [Byte] = []
        best.reserveCapacity(scanline)
        attempt.reserveCapacity(scanline)
        var previous: ArraySlice<Byte>?

        for row in stride(from: 0, to: image.rawPixels.count, by: scanline) {
            let current = image.rawPixels[row..<(row + scanline)]
            var chosen = candidates[0]
            var lowest = Int.max
            for candidate in candidates {
                attempt.removeAll(keepingCapacity: true)
                candidate.apply(to: current, previous: previous, bytesPerPixel: bytesPerPixel, into: &attempt)
                guard candidates.count > 1 else {
                    swap(&best, &attempt)
                    break
                }
                let sum = attempt.reduce(0) { $0 + Int(Int8(bitPattern: $1.underlying).magnitude) }
                if sum < lowest {
                    lowest = sum
                    chosen = candidate
                    swap(&best, &attempt)
                }
            }
            result.append(chosen.byte)
            result.append(contentsOf: best)
            previous = current
        }
        return result
    }
}
