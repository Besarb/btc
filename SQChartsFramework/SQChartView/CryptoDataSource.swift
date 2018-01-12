//
//  CryptoDataSource.swift
//  SQChartView
//
//  Created by Alex Rivera on 11.01.18.
//  Copyright © 2018 Swissquote. All rights reserved.
//

import Foundation
import SQChartsFramework

class CryptoDataSource: SQCDataSource {
	convenience init(symbol: String) {
		self.init()
		self.symbol = symbol
	}
	
	override init() {
		super.init()
		self.settings.maxPointsCount = 800
	}
	
	override func fetch(interval: Int) {
		super.fetch(interval: interval)
		
		self.interval = interval
		self.decimals = 8
		
		let from = self.symbol.substring(from: 0, length: 3)
		let to = self.symbol.substring(from: 3, length: 3)
		let limit: Int = 288
		let strUrl = "https://min-api.cryptocompare.com/data/histominute?fsym=\(from)&tsym=\(to)&limit=\(limit)&aggregate=\(interval)&e=Bitstamp"
		//print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "STRURL", strUrl)
		
		SQCRequest.fetchData(ACMHelper.instance.getSession(), strUrl: strUrl) { [unowned self] success, data in
			if !success { return }

			var quotes: [SQCQuote] = []
			let jsonDict: [String: Any] = data.jsonDictionary()
			
			guard let jsonArray = jsonDict["Data"] as? [[String: Any]] else { return }
			//["low": 193.77, "close": 195.08, "volumefrom": 327.2199999999999, "open": 194.63, "volumeto": 63571.3, "time": 1515594000, "high": 195.35]
			
			for json in jsonArray {
				if let open = json["open"] as? CGFloat,
					let high = json["high"] as? CGFloat,
					let low = json["low"] as? CGFloat,
					let close = json["close"] as? CGFloat,
					let time = json["time"] as? CGFloat {
					let q = SQCQuote()
					q.open = open
					q.high = high
					q.low = low
					q.close = close
					q.timestamp = time
					quotes.append(q)
				}
			}
			self.add(quotes)
		}
	}

}
