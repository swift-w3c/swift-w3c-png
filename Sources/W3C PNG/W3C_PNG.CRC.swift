internal import Byte

extension W3C_PNG {

    internal enum CRC {

        private static let table: [UInt32] = (0..<256).map { n in
            (0..<8).reduce(UInt32(n)) { c, _ in
                c & 1 != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1
            }
        }

        internal static func checksum(_ bytes: some Sequence<Byte>) -> UInt32 {
            bytes.reduce(UInt32(0xFFFF_FFFF)) { c, byte in
                table[Int((c ^ UInt32(byte.underlying)) & 0xFF)] ^ (c >> 8)
            } ^ 0xFFFF_FFFF
        }
    }
}
