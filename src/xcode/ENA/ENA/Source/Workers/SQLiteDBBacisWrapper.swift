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

enum SQLiteError: Error {
	case OpenDatabase(message: String)
	case Prepare(message: String)
	case Step(message: String)
	case Bind(message: String)
}

class SQLiteDBBacisWrapper {
	private let dbPointer: OpaquePointer?
	fileprivate var errorMessage: String {
		if let errorPointer = sqlite3_errmsg(dbPointer) {
			let errorMessage = String(cString: errorPointer)
			return errorMessage
		} else {
			return "No error message provided from sqlite."
		}
	}
    
	private init(dbPointer: OpaquePointer?) {
		self.dbPointer = dbPointer
	}
    
	deinit {
		sqlite3_close(dbPointer)
	}
    
	static func open(path: String, secret: String) throws -> SQLiteDBBacisWrapper {
		var db: OpaquePointer?
		if sqlite3_open(path, &db) == SQLITE_OK {
			if sqlite3_key(db, secret, Int32(secret.utf8CString.count)) == SQLITE_OK {
				return SQLiteDBBacisWrapper(dbPointer: db)
			} else {
				defer {
					if db != nil {
						sqlite3_close(db)
					}
				}
				if let errorPointer = sqlite3_errmsg(db) {
					let message = String(cString: errorPointer)
					throw SQLiteError.OpenDatabase(message: message)
				} else {
					throw SQLiteError
						.OpenDatabase(message: "No error message provided from sqlite.")
				}
			}
		} else {
			defer {
				if db != nil {
					sqlite3_close(db)
				}
			}

			if let errorPointer = sqlite3_errmsg(db) {
				let message = String(cString: errorPointer)
				throw SQLiteError.OpenDatabase(message: message)
			} else {
				throw SQLiteError
					.OpenDatabase(message: "No error message provided from sqlite.")
			}
		}
	}
}
extension SQLiteDBBacisWrapper {
	func prepareStatement(sql: String) throws -> OpaquePointer? {
		var statement: OpaquePointer?
		guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil)
			== SQLITE_OK else {
				throw SQLiteError.Prepare(message: errorMessage)
		}
		return statement
	}

	func createTable(sql: String) throws {
		let createTableStatement = try prepareStatement(sql: sql)
		defer {
			sqlite3_finalize(createTableStatement)
		}
		guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
			throw SQLiteError.Step(message: errorMessage)
		}
	}

	func insertKeyValue(key: String, data: Data) throws {
		let insertSql = "INSERT INTO kv(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value = ?;"
		do {
			try data.withUnsafeBytes { rawBufferPointer in
				let rawPtr = rawBufferPointer.baseAddress!
				let insertStatement = try prepareStatement(sql: insertSql)
				defer {
					sqlite3_finalize(insertStatement)
				}
				guard sqlite3_bind_text(insertStatement, 1, key, -1, nil) == SQLITE_OK &&
						sqlite3_bind_blob(insertStatement, 2, rawPtr, -1, nil) == SQLITE_OK &&
						sqlite3_bind_blob(insertStatement, 3, rawPtr, -1, nil) == SQLITE_OK
					else {
						throw SQLiteError.Bind(message: errorMessage)
				}
				guard sqlite3_step(insertStatement) == SQLITE_DONE else {
					throw SQLiteError.Step(message: errorMessage)
				}
				log(message: "Successfully inserted row..", level: .info)
			}
		}
	}
    
	func getValue(key: String) -> Data? {
		let querySql = "SELECT value FROM kv WHERE key = ?;"
		guard let queryStatement = try? prepareStatement(sql: querySql) else {
			return nil
		}
		defer {
			sqlite3_finalize(queryStatement)
		}
		guard sqlite3_bind_text(queryStatement, 1, key, -1, nil) == SQLITE_OK else {
			return nil
		}
		guard sqlite3_step(queryStatement) == SQLITE_ROW else {
			return nil
		}
		guard let queryResultCol1 = sqlite3_column_blob(queryStatement, 0) else {
			return nil
		}
		let size = sqlite3_column_bytes(queryStatement, 0)
		return Data(bytes: queryResultCol1, count: Int(size))
	}

	func clearAll() {
		let deleteSql = "DELETE FROM kv;"
		guard let deleteStatement = try? prepareStatement(sql: deleteSql) else {
			return
		}
		defer {
			sqlite3_finalize(deleteStatement)
		}
		guard sqlite3_step(deleteStatement) == SQLITE_DONE  else {
			logError(message: "Error deleting all entries")
			return
		}
		log(message: "Deleted all entries", level: .info)
	}
    
	func vacuum() {
		let deleteSql = "VACUUM;"
		guard let deleteStatement = try? prepareStatement(sql: deleteSql) else {
			return
		}
		defer {
			sqlite3_finalize(deleteStatement)
		}
		guard sqlite3_step(deleteStatement) == SQLITE_DONE  else {
			logError(message: "Error vaccuming the database")
			return
		}
		log(message: "Vacuumed Database table", level: .info)
	}
}
