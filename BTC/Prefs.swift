//
//  Prefs.swift
//  BTC
//
//  Created by Alex Rivera on 18.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import Foundation

enum ItemKey: String {
	case undefined = ""
	case orderId = "OrderID"
	case symbol = "Symbol"
	case amount = "Amount"
	case openPrice = "OpenPrice"
	case buyValue = "BuyValue"
	case openDate = "OpenDate"
	case closeDate = "CloseDate"
	case closePrice = "ClosePrice"

	case savedPositions = "BTXSavedItems"
	case archivedPositions = "BTXArchivedItems"
	case lastPrice = "BTCLastPrice"
}

class Prefs {
	
	private static let userDefault: UserDefaults = UserDefaults(suiteName: "group.com.rivera.alex.BTC.UserDefaults")!
	
	class func save() {
		self.userDefault.synchronize()
	}
	
	// MARK: - GETTERS
	
	class func string(_ itemKey: ItemKey) -> String? {
		return Prefs.string(forRawKey: itemKey.rawValue)
	}
	
	class func string(forRawKey rawKey: String) -> String? {
		return self.userDefault.string(forKey: rawKey)
	}
	
	/// - returns: empty array if the key does not exist.
	class func array<T>(_ itemKey: ItemKey) -> [T] {
		return Prefs.array(forRawKey: itemKey.rawValue)
	}
	
	/// - returns: empty array if the key does not exist.
	class func array<T>(forRawKey rawKey: String) -> [T] {
		if let tmpArray = self.userDefault.array(forKey: rawKey) as? [T] {
			return tmpArray
		}
		return [T]()
	}
	
	class func bool(_ itemKey: ItemKey) -> Bool {
		return Prefs.bool(forRawKey: itemKey.rawValue)
	}
	
	class func bool(forRawKey rawKey: String) -> Bool {
		return self.userDefault.bool(forKey: rawKey)
	}
	
	/// - returns: 0 if the key does not exist.
	class func int(_ itemKey: ItemKey) -> Int {
		return Prefs.int(forRawKey: itemKey.rawValue)
	}
	
	/// - returns: 0 if the key does not exist.
	class func int(forRawKey rawKey: String) -> Int {
		return self.userDefault.integer(forKey: rawKey)
	}
	
	/// - returns: 0 if the key does not exist.
	class func float(_ itemKey: ItemKey) -> Float {
		return Prefs.float(forRawKey: itemKey.rawValue)
	}
	
	/// - returns: 0 if the key does not exist.
	class func float(forRawKey rawKey: String) -> Float {
		return self.userDefault.float(forKey: rawKey)
	}
	
	/// - returns: empty dictionary if the key does not exist.
	class func dictionary(_ itemKey: ItemKey) -> [String: Any] {
		return Prefs.dictionary(forRawKey: itemKey.rawValue)
	}
	
	/// - returns: empty dictionary if the key does not exist.
	class func dictionary(forRawKey rawKey: String) -> [String: Any] {
		if let tmp = self.userDefault.dictionary(forKey: rawKey) {
			return tmp
		}
		return [:]
	}
	
	// MARK: - SETTERS
	class func set(_ value: Any, key itemKey: ItemKey) {
		Prefs.set(value, forRawKey: itemKey.rawValue)
	}
	
	class func set(_ value: Any, forRawKey rawKey: String) {
		self.userDefault.set(value, forKey: rawKey)
	}
	
	// MARK: - REMOVE
	class func remove(_ itemKey: ItemKey) {
		Prefs.remove(forRawKey: itemKey.rawValue)
	}
	
	class func remove(forRawKey rawKey: String) {
		self.userDefault.removeObject(forKey: rawKey)
	}
}
