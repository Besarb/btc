//
//  ACMDataSource.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 12.09.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import SQChartsFramework

protocol ACMDataSourceProtocol {
	func fetchQuedItems()
}

class ACMDataSource: SQCDataSource, ACMDataSourceProtocol {
	
	private typealias QueueItem = (symbol: String, interval: Int)
	private var fetchQueue: [QueueItem] = []
	
	private var fromDate: String {
		var date: Date
		if self.count == 0 {
			date = Date(timeIntervalSinceNow: -(Double(self.interval * self.settings.maxPointsCount)))
		} else {
			let q = self.quotes.last!
			date = Date(timeIntervalSince1970: Double(q.timestamp))
		}
		return ACMHelper.instance.df.string(from: date)
	}
	
	convenience init(symbol: String) {
		self.init()
		self.symbol = symbol
	}
	
	override init() {
		super.init()
		self.settings.maxPointsCount = 800
		ACMHelper.instance.delegates.append(self)
	}
	
	override func fetch(interval: Int) {
		super.fetch(interval: interval)
		
		self.interval = ACMHelper.instance.checkInterval(value: interval) ? interval : 60 //Default value
		self.decimals = ACMHelper.instance.decimals(for: symbol)
		
		if !ACMHelper.instance.ready {
			self.fetchQueue.append(QueueItem(symbol, interval))
			return
		}
		
		if self.decimals == 0 {
			print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "ERROR: symbol \(symbol) NOT FOUND!")
			return
		}
		
		let strUrl = ACMHelper.instance.url(symbol: symbol, interval: interval, dateFrom: self.fromDate)
		//print("strUrl", strUrl)
		
		SQCRequest.fetchData(ACMHelper.instance.getSession(), strUrl: strUrl) { [unowned self] success, data in
			if !success { return }
			
			var quotes: [SQCQuote] = []
			let jsonArray: [[String: CGFloat]] = data.jsonArray()
			for json in jsonArray {
				let q = SQCQuote()
				q.updateACM(json)
				quotes.append(q)
			}
			self.add(quotes)
		}
	}
	
	func fetchQuedItems() {
		if self.fetchQueue.count > 1 {
			print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "COUNT", self.fetchQueue.count)
		}
		
		var queue:[QueueItem] = []
		queue.append(contentsOf: self.fetchQueue)
		self.fetchQueue.removeAll()
		
		for item in queue {
			self.fetch(symbol: item.symbol, interval: item.interval)
		}
	}
}

class ACMHelper {
	static let instance = ACMHelper()
	
	private let urlLive = "http://chartfx.swissquote.com/quotes/Quotes?"
	private let urlDemo = "http://demo-chartfx.swissquote.com/quotes/Quotes?"
	
	var delegates: [ACMDataSourceProtocol] = []
	var intervals: [ChartInterval] = []
	var instruments: [ChartInstrument] = []
	var ready: Bool {
		return self.dateFormatDone && self.intervalsDone && self.instrumentsDone
	}
	
	let defaultInterval = ChartInterval(key: "MinuteInterval", amount: 1, interval: 60)
	
	public lazy var df: DateFormatter = {
		let df = DateFormatter()
		df.locale = Locale.current
		df.timeZone = TimeZone(secondsFromGMT: 0)
		return df
	}()
	
	private var dateFormatDone: Bool = false { didSet { self.checkIfReady() } }
	private var intervalsDone: Bool = false { didSet { self.checkIfReady() } }
	private var instrumentsDone: Bool = false { didSet { self.checkIfReady() } }
	private var chartSession: URLSession? = nil
	
	init() {}
	
	func start() {
		self.fetchDateFormat()
		self.fetchIntervals()
		self.fetchInstruments()
	}
	
	private func checkIfReady() {
		if self.ready {
			for delegate in self.delegates {
				delegate.fetchQuedItems()
			}
		}
	}
	
	func getSession() -> URLSession {
		if let session = self.chartSession {
			return session
		} else {
			let configuration = URLSessionConfiguration.default
			configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
			
			let session = URLSession(configuration: configuration, delegate: SQCRequestSessionDelegate(), delegateQueue: OperationQueue.main)
			session.sessionDescription = "ChartsSession"
			
			self.chartSession = session
			return session
		}
	}
	
	func invalidateSession() {
		if let session = self.chartSession {
			session.invalidateAndCancel()
		}
		self.chartSession = nil
	}
	
	func fetchDateFormat() {
		let strUrl = self.url(service: "getConfiguration")
		
		SQCRequest.fetchData(self.getSession(), strUrl: strUrl) { [unowned self] success, data in
			let json: [String: Any] = data.jsonDictionary()
			if let format = json["date.format"] as? String {
				self.df.dateFormat = format
			} else {
				// Default value
				self.df.dateFormat = "dd.MM.yyyy HH:mm:ss"
			}
			print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "FETCH-DATE-FORMAT: \(success)")
			
			self.dateFormatDone = success
			if !success {
				DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
					ACMHelper.instance.fetchDateFormat()
				}
			}
		}
	}
	
	func fetchIntervals() {
		self.intervals.removeAll()
		let strUrl = self.url(service: "getAvailableGranularities")
		
		SQCRequest.fetchData(self.getSession(), strUrl: strUrl) { [unowned self] success, data in
			let jsonArray: [[String: Any]] = data.jsonArray()
			for json in jsonArray {
				if let intervalClass = json["intervalClass"] as? String,
					let parameter = json["parameter"] as? Int,
					let granularity = json["granularity"] as? Int {
					if intervalClass == "TickInterval" { continue }
					let ci = ChartInterval(key: intervalClass, amount: parameter, interval: granularity)
					self.intervals.append(ci)
					self.intervals.sort(by: { $0.value < $1.value })
				}
			}
			print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "FETCH-INTERVALS: \(success)")
			
			self.intervalsDone = success
			if success {
				NotificationCenter.default.post(name: NSNotification.Name.chartsIntervalsFetched, object: nil)
				//NotificationCenter.default.post(name: .chartsIntervalsFetched, object: nil)
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
					ACMHelper.instance.fetchIntervals()
				}
			}
		}
	}
	
	func fetchInstruments() {
		self.instruments.removeAll()
		let strUrl = self.url(service: "getChartInstrumentList")
		
		SQCRequest.fetchData(self.getSession(), strUrl: strUrl) { [unowned self] success, data in
			let jsonArray: [[String: Any]] = data.jsonArray()
			for json in jsonArray {
				if let code = json["code"] as? String, let decimals = json["decimals"] as? Int {
					let instrument = ChartInstrument(symbol: code, decimals: decimals)
					self.instruments.append(instrument)
					self.instruments.sort(by: { $0.symbol < $1.symbol })
				}
			}
			print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "FETCH-INSTRUMENTS: \(success)")
			
			self.instrumentsDone = success
			if !success {
				DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
					ACMHelper.instance.fetchInstruments()
				}
			}
		}
	}
	
	func interval(for value: Int) -> ChartInterval {
		for interval in self.intervals {
			if interval.value == value {
				return interval
			}
		}
		return ChartInterval(key: "???", amount: 1, interval: 60)
	}
	
	func checkInterval(value: Int) -> Bool {
		for chartInterval in self.intervals {
			if chartInterval.value == value {
				return true
			}
		}
		return false
	}
	
	func decimals(for symbol: String) -> Int {
		for instrument in self.instruments {
			if instrument.symbol == symbol {
				return instrument.decimals
			}
		}
		return 0
	}
	
	func url(service: String) -> String {
		return "\(self.urlLive)service=\(service)&output=json"
	}
	
	func url(symbol: String, interval: Int, dateFrom: String) -> String {
		let strUrl = self.url(service: "getAssetHistory")
		let params = "&asset=\(symbol)&granularity=\(interval)&dateFrom=\(dateFrom)"
		return "\(strUrl)\(params.urlEncoded)"
	}
}

struct ChartInterval {
	var key: String = ""
	var amount: Int = 0
	var value: Int = 0
	init(key: String, amount: Int, interval: Int) {
		self.key = key
		self.amount = amount == 0 ? 1 : amount
		self.value = interval
	}
}

struct ChartInstrument {
	var symbol: String = ""
	var decimals: Int = 0
}

extension Notification.Name {
	static let chartsIntervalsFetched = Notification.Name("atk.notification.chartsIntervalsFetched")
	static let chartsInstrumentsFetched = Notification.Name("atk.notification.chartsInstrumentsFetched")
}

extension String {
	var urlEncoded: String {
		get {
			if let encoded = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
				return encoded
			}
			return self
		}
	}
}
