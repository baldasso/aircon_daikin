import Foundation
import Security

/// Somewhere to keep one opaque blob.
public protocol BlobStore: Sendable {
    func read() throws -> Data?
    func write(_ data: Data) throws
}

public enum StoreError: Error, Equatable {
    case keychain(OSStatus)
}

/// A single generic-password item in the login keychain.
public struct KeychainBlobStore: BlobStore {
    private let service: String
    private let account: String

    public init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    public func read() throws -> Data? {
        var lookup = query
        lookup[kSecReturnData as String] = true
        var result: AnyObject?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
        return result as? Data
    }

    public func write(_ data: Data) throws {
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        guard status == errSecItemNotFound else {
            guard status == errSecSuccess else { throw StoreError.keychain(status) }
            return
        }
        var item = query
        item[kSecValueData as String] = data
        let added = SecItemAdd(item as CFDictionary, nil)
        guard added == errSecSuccess else { throw StoreError.keychain(added) }
    }
}

/// A plain file. Used by tests and for development runs; never holds the user's real keys by default.
public struct FileBlobStore: BlobStore {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func read() throws -> Data? {
        FileManager.default.fileExists(atPath: url.path) ? try Data(contentsOf: url) : nil
    }

    public func write(_ data: Data) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
