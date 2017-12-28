//
//  BTCManager.swift
//  BTC
//
//  Created by Alex Rivera on 22.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import Foundation
import UIKit

class BTCHelper {
	static let availableCurrencies: [String: Currency] = [
		"etheur": Currency("etheur", "Ethereum/EUR"),
		"ltceur": Currency("ltceur", "LiteCoin/EUR"),
		"btceur": Currency("btceur", "Bitcoin/EUR"),
		"bcheur": Currency("bcheur", "BTCash/EUR"),
		"xrpeur": Currency("xrpeur", "Ripple/EUR")]

	class var symbols: [String] {
		let list = Array(BTCHelper.availableCurrencies.keys)
		return list.sorted()
	}
	
	class var currencies: [Currency] {
		let list = Array(BTCHelper.availableCurrencies.values)
		return list.sorted()
	}
	
	//MARK: Currencies
	class func currency(_ symbol: String) -> Currency? {
		guard let currency = BTCHelper.availableCurrencies[symbol] else { return nil }
		return currency
	}
	
	class func loadVisibleCurencies() -> [Currency] {
		//["currencies": ["etheur","ltceur",...]]
		let json = BTCHelper.loadJson(fileName: "currencies.json")
		if json.count == 0 {
			let currencies = BTCHelper.currencies
			BTCHelper.saveVisibleCurrencies(currencies)
			return currencies
		}
		
		guard let names = json["currencies"] as? [String] else {
			return BTCHelper.currencies
		}
		
		var currencies: [Currency] = []
		for name in names {
			guard let currency = BTCHelper.availableCurrencies[name] else { continue }
			currencies.append(currency)
		}
		
		if currencies.count == 0 {
			return BTCHelper.currencies
		}
		return currencies
	}
	
	class func saveVisibleCurrencies(_ currencies: [Currency]) {
		let symbols: [String] = currencies.map{ $0.symbol }
		BTCHelper.saveJson(fileName: "currencies.json", json: ["currencies": symbols])
	}
	
	//MARK: Positions
	
	class func loadPositions() -> [Position] {
		let json = BTCHelper.loadJson(fileName: "positions.json")
		
		var positions: [Position] = []
		if let posList = json["positions"] as? [[String: Any]] {
			for pos in posList {
				positions.append(Position(json: pos))
			}
		}
		return positions
	}
	
	class func savePositions(_ positions: [Position]) {
		var posData: [[String: Any]] = []
		for pos in positions {
			posData.append(pos.json)
		}
		
		var data: [String: Any] = [:]
		data["positions"] = posData
		
		BTCHelper.saveJson(fileName: "positions.json", json: data)
	}
	
	class func appendPosition(_ position: Position) {
		var positions = BTCHelper.loadPositions()
		let index = positions.index(of: position)
		if index >= 0 {
			positions.remove(at: index)
		}
		positions.append(position)
		BTCHelper.savePositions(positions)
	}
	
	class func deletePosition(_ position: Position) {
		var positions = BTCHelper.loadPositions()
		let index = positions.index(of: position)
		if index >= 0 {
			positions.remove(at: index)
			BTCHelper.savePositions(positions)
		}
	}
}

extension Array where Element: Position {
	func index(of pos: Position) -> Int {
		return self.index(orderId: pos.orderId)
	}
	
	func index(orderId: Int) -> Int {
		for (index, pos) in self.enumerated() {
			if pos.orderId == orderId {
				return index
			}
		}
		return -1
	}
}

extension BTCHelper {
	class func loadJson(fileName: String) -> [String: Any] {
		do {
			guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return [:] }
			let path = dir.appendingPathComponent(fileName)
			
			let data = try Data(contentsOf: path, options: Data.ReadingOptions.uncached)
			let json:[String: Any] = data.jsonDictionary()
			
			return json
		}
		catch {
			print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "COULD NOT LOAD FILE", fileName, error.localizedDescription)
		}
		return [:]
	}
	
	class func saveJson(fileName: String, json: [String: Any]) {
		do {
			guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
			let path = dir.appendingPathComponent(fileName)
			print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "PATH", path)
			
			let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
			
			try jsonData.write(to: path, options: .atomic)
			
		} catch {
			print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "COULD NOT SAVE FILE", fileName, error.localizedDescription)
		}
	}
	
	class func fetchCurrenciesInfo() {
		
	}
}


//MARK: -
class Position {
	var json: [String: Any] {
		get {
			return [ItemKey.symbol.rawValue: self.symbol, ItemKey.orderId.rawValue: self.orderId, ItemKey.openDate.rawValue: self.openDate.timeIntervalSince1970, ItemKey.amount.rawValue: self.amount, ItemKey.openPrice.rawValue: self.openPrice, ItemKey.closeDate.rawValue: self.closeDate.timeIntervalSince1970, ItemKey.closePrice.rawValue: self.closePrice]
		}
	}
	
	var symbol: String {
		guard let currency = self.currency else { return "???" }
		return currency.symbol
	}
	var name: String {
		guard let currency = self.currency else { return "???" }
		return currency.name
	}
	
	var currency: Currency?
	
	var orderId: Int = 0
	var openDate: Date = Date()
	var openPrice: Double = 0
	var amount: Double = 0

	//TODO: for archive
	var closeDate: Date = Date()
	var closePrice: Double = 0
	
	var value: Double { return self.amount * self.openPrice }
	var pl: Double {
		if let c = self.currency {
			return (c.sell - self.openPrice) * self.amount
		}
		return 0
	}
	var plPercent: Double { return self.value > 0 ? self.pl/self.value * 100.0 : 0.0 }
	//var plColor: UIColor { return self.pl > 0 ? UIColor.positive : UIColor.negative }
	
	var isValid: Bool {
		return self.amount > 0
	}
	
	init(json: [String: Any]) {
		self.orderId = json.toInt(ItemKey.orderId.rawValue)
		self.openDate = json.toDate(ItemKey.openDate.rawValue)
		self.openPrice = json.toDouble(ItemKey.openPrice.rawValue)
		self.amount = json.toDouble(ItemKey.amount.rawValue)
		self.currency = BTCHelper.currency(json.toString(ItemKey.symbol.rawValue))
		self.closeDate = json.toDate(ItemKey.closeDate.rawValue)
		self.closePrice = json.toDouble(ItemKey.closePrice.rawValue)
	}
}


func ==(lhs: Currency, rhs: Currency) -> Bool {
	return lhs.symbol == rhs.symbol
}
func <(lhs: Currency, rhs: Currency) -> Bool {
	return lhs.symbol < rhs.symbol
}

class Currency: Comparable {
	static let notifName: String = "CURRENCY_UPDATE"
	var json: [String: Any] = [:]//["open": "3405.99", "high": "3509.88", "low": "3104.90", "last": "3264.00", "bid": "3262.76", "ask": "3264.00", "timestamp": "1503388477"]
	
	var symbol: String = ""
	var name: String = ""
	var decimals: Int = 8
	
	var open: Double { return self.json.toDouble("open") }
	var high: Double { return self.json.toDouble("high") }
	var low: Double { return self.json.toDouble("low") }
	var last: Double { return self.json.toDouble("last") }
	var buy: Double { return self.json.toDouble("bid") }
	var sell: Double { return self.json.toDouble("ask") }
	var date: Date { return self.json.toDate("timestamp") }
	
	var change: Double { return self.sell - self.open }
	var changePercent: Double { return self.open > 0 ? self.change/self.open * 100.0 : 0.0 }
	
	init(_ symbol: String, _ name: String, _ decimals: Int = 8) {
		self.symbol = symbol
		self.name = name
		self.decimals = decimals
	}
	
	func update() {
		BTCRequest.fetch(symbol: self.symbol){ [unowned self] success in
			if !success { return }
			NotificationCenter.default.post(name: Notification.Name(self.symbol), object: self)
			NotificationCenter.default.post(name: Notification.Name(Currency.notifName), object: nil)
		}
	}
}
