import CommonCrypto
import Foundation

/// AES-128 in CFB128 mode: the cipher the device uses for every frame.
enum AESCFB {
    enum Operation {
        case encrypt, decrypt

        var ccValue: CCOperation { CCOperation(self == .encrypt ? kCCEncrypt : kCCDecrypt) }
    }

    static func apply(_ operation: Operation, to input: Data, key: Data, iv: Data) throws -> Data {
        guard key.count == kCCKeySizeAES128, iv.count == kCCBlockSizeAES128 else { throw AirconError.cipherFailure }
        let cryptor = try makeCryptor(operation, key: key, iv: iv)
        defer { CCCryptorRelease(cryptor) }

        var output = Data(count: input.count)
        var written = 0
        let status = output.withUnsafeMutableBytes { out in
            input.withUnsafeBytes { inp in
                CCCryptorUpdate(cryptor, inp.baseAddress, input.count, out.baseAddress, input.count, &written)
            }
        }
        guard status == kCCSuccess, written == input.count else { throw AirconError.cipherFailure }
        return output
    }

    private static func makeCryptor(_ operation: Operation, key: Data, iv: Data) throws -> CCCryptorRef {
        var cryptor: CCCryptorRef?
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                CCCryptorCreateWithMode(
                    operation.ccValue, CCMode(kCCModeCFB), CCAlgorithm(kCCAlgorithmAES), CCPadding(ccNoPadding),
                    ivBytes.baseAddress, keyBytes.baseAddress, key.count, nil, 0, 0, 0, &cryptor
                )
            }
        }
        guard status == kCCSuccess, let cryptor else { throw AirconError.cipherFailure }
        return cryptor
    }
}
