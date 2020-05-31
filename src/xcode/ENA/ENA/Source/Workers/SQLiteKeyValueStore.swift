// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import Foundation
import Security

class SQLiteKeyValueStore {
	var db: SQLiteDBBacisWrapper?

	/// - parameter url: URL on disk where the SQLite DB should be initialized
	init(with url: URL) {
		let sqlStmt = """
		CREATE TABLE IF NOT EXISTS kv (
			key TEXT UNIQUE,
			value BLOB
		);
		"""

		db = nil
		var key: String
		if let keyData = loadFromKeychain(key: "dbKey") {
			key = String(decoding: keyData, as: UTF8.self)
		} else {
			key = UUID().uuidString
			if savetoKeychain(key: "dbKey", data: Data(key.utf8)) == noErr {
				logError(message: "Unable to open save Key to Keychain")
			}
		}
		do {
			db = try SQLiteDBBacisWrapper.open(path: url.absoluteString, secret: key)
			log(message: "Successfully opened connection to database.", level: .info)
			try db?.createTable(sql: sqlStmt)
		} catch {
			logError(message: "Unable to open Database")
			return
		}
	}

	private func getData(for key: String) -> Data? {
		return db?.getValue(key: key)
	}

	private func setData(_ data: Data?, for key: String) {
		guard let data = data else {
			return
		}
		do {
			try db?.insertKeyValue(key: key, data: data)
		} catch {
			return
		}
	}

	func clearAll() {
		db?.clearAll()
		db?.vacuum()
	}

	func flush() {
		db?.clearAll()
		db?.vacuum()
	}

	subscript(key: String) -> Data? {
		get {
			getData(for: key)
		}
		set {
			setData(newValue, for: key)
		}
	}

	/// - important: Assumes data was encoded with a `JSONEncoder`!
	subscript<Model: Codable>(key: String) -> Model? {
		get {
			guard let data = getData(for: key) else {
				return nil
			}
			do {
				return try JSONDecoder().decode(Model.self, from: data)
			} catch {
				logError(message: "Error when decoding value for reading from K/V SQLite store: \(error.localizedDescription)")
				return nil
			}
		}
		set {
			do {
				let encoded = try JSONEncoder().encode(newValue)
				setData(encoded, for: key)
			} catch {
				logError(message: "Error when encoding value for inserting into K/V SQLite store: \(error.localizedDescription)")
			}
		}
	}
}

/// Keychain Extension for storing and loading the Database Key in the Keychain
extension SQLiteKeyValueStore {
	func savetoKeychain(key: String, data: Data) -> OSStatus {
		let query = [
			kSecClass as String: kSecClassGenericPassword as String,
			kSecAttrAccount as String: key,
			kSecValueData as String: data ] as [String: Any]

		SecItemDelete(query as CFDictionary)
		return SecItemAdd(query as CFDictionary, nil)
	}

	func loadFromKeychain(key: String) -> Data? {
		let query = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: kCFBooleanTrue!,
			kSecMatchLimit as String: kSecMatchLimitOne] as [String: Any]

		var dataTypeRef: AnyObject?
		let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
		if status == noErr {
			return dataTypeRef as? Data ?? nil
		} else {
			return nil
		}
	}
}
extension Data {
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}
