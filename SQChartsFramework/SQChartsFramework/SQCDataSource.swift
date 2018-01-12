//
//  DataSource.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 25.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit


open class SQCDataSource {
	var delegate: SQCViewProtocol?
	
	public var settings = SQCSettings()
	
	public var symbol: String = "" {
		willSet {
			if self.symbol.length > 0 && self.symbol != newValue {
				self.quotes.removeAll()
			}
		}
	}
	public var interval: Int = 0
	public var decimals: Int = 4
	
	public var quotes: [SQCQuote] = []
	public var count: Int { return self.quotes.count }
	public var lastIndex: Int { return self.count - 1 }
	
	private lazy var calendar: Calendar = {
		return Locale.current.calendar
	}()
	
	public init() {}
	
	public func add(_ quote: SQCQuote) {
		self.add([quote])
	}
	
	public func add(_ newQuotes: [SQCQuote]) {
		if newQuotes.count == 0 { return }
		
		var isFirstLoad: Bool = false
		if self.count > 0 {
			let newQuote = newQuotes[0]
			var cpt: Int = 1
			var index: Int = self.count - cpt
			while index >= 0 && self.quotes[index].timestamp >= newQuote.timestamp {
				cpt += 1
				index = self.count - cpt
			}
			cpt -= 1
			if cpt > 0 {
				self.quotes.removeLast(cpt)
			}
		} else {
			isFirstLoad = true
		}
		
		self.quotes.append(contentsOf: newQuotes)
		
		if self.settings.maxPointsCount > 0 && self.count > self.settings.maxPointsCount {
			self.quotes.removeFirst(self.count - self.settings.maxPointsCount)
		}
		
		self.delegate?.quotesAdded(isFirstLoad: isFirstLoad)
	}
	
	open func fetch(interval: Int) {
		if self.symbol == "" {
			print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "NO SYMBOL DEFINED")
			return
		}
		if interval != self.interval {
			self.quotes.removeAll()
		}
		self.interval = interval
		
		//Subclass here
	}
	
	open func fetch(symbol: String, interval: Int) {
		self.symbol = symbol
		self.fetch(interval: interval)
	}
	
	func updateLast(_ quote: SQCQuote) {
		guard let lastQuote = self.quotes.last else { return }
		
		if quote.timestamp > lastQuote.timestamp {
			self.add(quote)
			return
		}
		
		lastQuote.high = max(lastQuote.high, quote.high)
		lastQuote.low = min(lastQuote.low, quote.low)
		lastQuote.close = quote.close
	}
	
	func quotes(for rangeIndex: RangeIndex) -> ArraySlice<SQCQuote> {
		let range = rangeIndex.start...rangeIndex.end
		return self.quotes[range]
	}
	
	func metricsY(type: SQCMetricsY.MinMaxType, size: CGSize, offset: CGFloat, minPointWidth: CGFloat, minPointMargin: CGFloat, extendRangeBy: Int = 0) -> SQCMetricsY {
		if self.count == 0 {
			return SQCMetricsY()
		}
		
		var metrics = SQCMetricsY()
		metrics.frameSize = size
		metrics.frameOffset = offset

		let visibleRect = CGRect(x: offset, y: 0, width: size.width, height: size.height)
		
		var xDelta: CGFloat = 0
		var pointWidth = minPointWidth
		var pointMargin = minPointMargin
		
		if minPointWidth > 0 {
			// Compute optimal item width (like for candle sticks)
			let nbItems: CGFloat = floor(size.width / (minPointWidth + minPointMargin))
			
			if nbItems > CGFloat(self.count) {
				// All items fit in visibleRect AND empty space remains -> resize items
				let tmpWidth = min(20.0, floor(size.width / CGFloat(self.count)))
				pointMargin = max(1.0, floor(tmpWidth / 4))
				pointWidth = tmpWidth - pointMargin
			} else {
				metrics.totalContentWidth = (pointWidth + pointMargin) * CGFloat(self.count)
			}
			
			xDelta = pointWidth + pointMargin
			
		} else {
			xDelta = size.width / CGFloat(self.count)
		}
		
		// Find quotes visible in visibleRect
		var startIndex = offset == 0 ? 0 : Int(floor(offset / xDelta))
		var endIndex = min(startIndex + Int(ceil(visibleRect.width / xDelta)), self.count - 1)
		
		if extendRangeBy > 0 {
			startIndex = max(0, startIndex - extendRangeBy)
			endIndex = min(endIndex + extendRangeBy, self.count - 1)
		}
		if startIndex >= endIndex && endIndex > 0 {
			startIndex = endIndex - 1
		}
		let rangeIndex = RangeIndex(startIndex, endIndex)
		
		
		// Build Metrics
		let visibleQuotes = self.quotes(for: rangeIndex)
		
		switch type {
		case .highLow:
			metrics.low = visibleQuotes.map{ $0.low }.min()!
			metrics.high = visibleQuotes.map{ $0.high }.max()!
			
		case .volume:
			metrics.low = visibleQuotes.map{ $0.volume }.min()!
			metrics.high = visibleQuotes.map{ $0.volume }.max()!
			
		default:
			metrics.low = visibleQuotes.map{ $0.close }.min()!
			metrics.high = visibleQuotes.map{ $0.close }.max()!
		}
		
		metrics.range = rangeIndex
		metrics.pointWidth = pointWidth
		metrics.pointMargin = pointMargin
		metrics.xDelta = xDelta
		
		metrics.refPrice = self.quotes[0].close
		metrics.lastClosePrice = self.quotes[self.count - 1].close
		
		return metrics
	}
	
	func metricsX(_ metricsY: SQCMetricsY) -> SQCMetricsX? {
		if self.count == 0 { return nil }
		
		let periodStart = Double(self.quotes[metricsY.range.start].timestamp)
		let periodEnd = Double(self.quotes[metricsY.range.end].timestamp)
		let visiblePeriod = periodEnd - periodStart
		
		if visiblePeriod <= 0 { return nil }
		
		let periods = [10*TimeInterval.year, 3*TimeInterval.year, TimeInterval.year,
		               3*TimeInterval.month, 2*TimeInterval.month, TimeInterval.month,
		               10*TimeInterval.day, 5*TimeInterval.day, TimeInterval.day,
					   5*TimeInterval.hour, 3*TimeInterval.hour, TimeInterval.hour,
		               10*TimeInterval.minute, 5*TimeInterval.minute, 2.5*TimeInterval.minute, TimeInterval.minute,
		               30, 10, 1]
		
		var periodIndex: Int = -1
		for (index, period) in periods.enumerated() {
			if period < visiblePeriod {
				periodIndex = index
				break
			}
		}
		
		//print("-------------------")
		//print("INTERVAL:", self.interval)
		//print("VISIBLE PERIOD:", visiblePeriod, "HOURS DISPLAYED:", (visiblePeriod/(60*60)).fmt(decimals: 1))
		//print("PERIOD VALUE:", periods[periodIndex])
		//print("PERIOD INDEX:", periodIndex)

		
		let dateStart = Date(timeIntervalSince1970: Double(self.quotes.first!.timestamp))
		let dateEnd   = Date(timeIntervalSince1970: Double(self.quotes.last!.timestamp))
		let calendarUnits: Set<Calendar.Component> = [.year, .month, .day, .weekday, .weekdayOrdinal, .timeZone, .hour]
		
		var startDateComponents = self.calendar.dateComponents(calendarUnits, from: dateStart)
		var stepComponents = DateComponents()
		
		//print("*** PERIOD-INDEX: \(periodIndex)")
		
		switch periodIndex {
		case 0:
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			stepComponents.year = 5;
			SQCUtils.dateFormatter.dateFormat = "yyyy";
			
		case 1:
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			stepComponents.year = 1;
			SQCUtils.dateFormatter.dateFormat = "yyyy";
			
		case 2:
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			stepComponents.month = 3;
			SQCUtils.dateFormatter.dateFormat = "MMM yyyy";
			
		case 3:
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			stepComponents.month = 2;
			SQCUtils.dateFormatter.dateFormat = "MMM yyyy";
			
		case 4:
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			stepComponents.month = 1;
			SQCUtils.dateFormatter.dateFormat = "MMM yyyy";
			
		case 5:
			startDateComponents.month = 1;
			startDateComponents.day = 1;
			stepComponents.day = 7;
			SQCUtils.dateFormatter.dateFormat = "dd MMM";
			
		case 6:
			var weekdayDifference = startDateComponents.weekday! - self.calendar.firstWeekday;
			if (weekdayDifference < 0) {
				weekdayDifference = 7 + weekdayDifference;
			}
			
			startDateComponents.day = startDateComponents.day! - weekdayDifference;
			stepComponents.day = 7;
			SQCUtils.dateFormatter.dateFormat = "dd MMM";
			
		case 7:
			stepComponents.day = 1;
			SQCUtils.dateFormatter.dateFormat = "dd MMM";
			
		case 8:
			startDateComponents.hour! += 1
			stepComponents.hour = 6;
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short
			
		case 9:
			startDateComponents.hour! += 1
			stepComponents.hour = 3;
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short

		case 10:
			startDateComponents.hour! += 1
			stepComponents.hour = 1
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short
			
		case 11:
			stepComponents.minute = 30
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short
			
		case 12:
			stepComponents.minute = 10
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short
			
		case 13:
			stepComponents.minute = 5
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short
			
		case 14:
			stepComponents.minute = 1
			SQCUtils.dateFormatter.dateStyle = .none
			SQCUtils.dateFormatter.timeStyle = .short
			
		case 15:
			stepComponents.second = 30
			SQCUtils.dateFormatter.dateFormat = "HH:mm:ss";
			
		case 16:
			stepComponents.second = 10
			SQCUtils.dateFormatter.dateFormat = "HH:mm:ss";
			
		case 17:
			stepComponents.second = 2
			SQCUtils.dateFormatter.dateFormat = "HH:mm:ss";
			
		case 18:
			stepComponents.second = 1
			SQCUtils.dateFormatter.dateFormat = "HH:mm:ss";
			
		default:
			break
		}
		
		let timeLow = self.quotes.first!.timestamp
		let timeHigh = self.quotes.last!.timestamp
		
		var tickDate = self.calendar.date(from: startDateComponents)!
		
		var chartPoints: [SQCPoint] = []
		var pointIndex: Int = 0
		
		while (tickDate.timeIntervalSince1970 < dateEnd.timeIntervalSince1970) {
			if tickDate.timeIntervalSince1970 > dateStart.timeIntervalSince1970 {
				
				let time = CGFloat(tickDate.timeIntervalSince1970)
				let item:(index: Int, quote: SQCQuote?) = SQCUtils.findQuote(closeTo: time, dataSource: self, timeLow, timeHigh)
				
				if let _ = item.quote {
					chartPoints.append(
						SQCPoint(value: time, valueFmt: SQCUtils.dateFormatter.string(from: tickDate), pointX: (CGFloat(item.index) * metricsY.xDelta), quoteIndex: item.index, pointIndex: pointIndex)
					)
					pointIndex += 1
				}
			}
			tickDate = self.calendar.date(byAdding: stepComponents, to: tickDate)!
		}
		
		var metricsX = SQCMetricsX()
		metricsX.chartPoints = chartPoints
		metricsX.stepComponents = stepComponents
		metricsX.xDelta = metricsY.xDelta
		
		return metricsX
	}
}

// MARK: - DEBUG
extension SQCDataSource {
	public func firstQuote() -> SQCQuote? {
		return self.quotes.first
	}
	
	public func lastQuote() -> SQCQuote? {
		return self.quotes.last
	}
	
	public func loadSample(fileName: String, isACM: Bool = false) {
		self.quotes.removeAll()
		let bundle = Bundle(for: SQCDataSource.self)
		
		guard let url = bundle.url(forResource: fileName, withExtension: "json") else { print("PATH NOT FOUND FOR \(fileName)"); return }
		
		do {
			let data = try Data(contentsOf: url, options: Data.ReadingOptions.uncached)
			let json:[[String: CGFloat]] = data.jsonArray()
			
			var items: [SQCQuote] = []
			
			for value in json {
				let quote = SQCQuote()
				if isACM {
					quote.updateACM(value)
				} else {
					quote.update(value)
				}
				items.append(quote)
			}
			
			self.add(items)
			print("QUOTES LOADED FROM '\(fileName)'. COUNT: \(self.count)")
			//dump(self.quotes)
		}
		catch {
			print("DATASOURCE.LOAD_SAMPLE ERROR: \(error.localizedDescription)")
		}
	}
}

struct SQCPoint {
	var value: CGFloat
	var valueFmt: String
	var percent: CGFloat
	var percentFmt: String
	var point: CGPoint
	var quoteIndex: Int
	var pointIndex: Int
	
	var x: CGFloat {
		return self.point.x
	}
	var y: CGFloat {
		return self.point.y
	}
	
	var desc: String {
		return "val: \(value), %: \(percent), point: \(point), qIdx: \(quoteIndex), pIdx: \(pointIndex)"
	}
	
	init(value: CGFloat = 0, valueFmt: String = "", percent: CGFloat = 0, point: CGPoint = CGPoint.zero, quoteIndex: Int = -1, pointIndex: Int = 0) {
		self.value = value
		self.valueFmt = valueFmt
		self.percent = percent
		self.percentFmt = String(format: "%.2f%%", percent)
		self.point = point
		self.quoteIndex = quoteIndex
		self.pointIndex = pointIndex
	}
	
	init(value: CGFloat, valueFmt: String = "", percent: CGFloat = 0, pointX: CGFloat = 0, pointY: CGFloat = 0, quoteIndex: Int = -1, pointIndex: Int = 0) {
		self.init(value: value, valueFmt: valueFmt, percent: percent, point: CGPoint(x: pointX, y: pointY), quoteIndex: quoteIndex, pointIndex: pointIndex)
	}
	
	func isEmpty() -> Bool {
		return self.value == 0 && self.percent == 0
	}
}

struct SQCMetricsX {
	var stepComponents = DateComponents()
	var xDelta: CGFloat = 0.0
	var chartPoints: [SQCPoint] = []
	
	init(_ chartPoints: [SQCPoint] = []) {
		self.chartPoints = chartPoints
	}
}

struct SQCMetricsY {
	enum MinMaxType {
		case close
		case highLow
		case volume
	}
	
	var high: CGFloat = 0.0
	var low: CGFloat = 0.0
	
	var refPrice: CGFloat = 0
	var lastClosePrice: CGFloat = 0
	
	var xDelta: CGFloat = 0
	var yDelta: CGFloat { return self.high - self.low }
	
	var pointWidth: CGFloat = 0.0
	var pointMargin: CGFloat = 0.0
	var totalContentWidth: CGFloat = 0 //The width of all the points
	var range: RangeIndex = (0,0)
	
	var frameSize: CGSize = CGSize.zero
	var frameOffset: CGFloat = 0.0
	var drawRect: CGRect {
		return CGRect(x: self.frameOffset, y: 0, width: self.frameSize.width, height: self.frameSize.height)
	}
	var maxX: CGFloat {
		return self.frameOffset + self.frameSize.width
	}
	var lastChartPoint: SQCPoint {
		get {
			if self.refPrice.between(self.low, self.high) {
				let lastPercent = (self.lastClosePrice - self.refPrice) / self.refPrice
				return SQCPoint(value: self.refPrice, percent: lastPercent, pointY: SQCUtils.yPos(self.refPrice, self))
			}
			return SQCPoint()
		}
	}
	var desc: String {
		return "METRICS - high: \(high), low: \(low), ref: \(refPrice), last: \(lastClosePrice), xD: \(xDelta), yD: \(yDelta), ptWidth: \(pointWidth), ptMargin: \(pointMargin), range: \(range), drawRect: \(drawRect)"
	}
}

public class SQCQuote {
	//TODO: remove public
	public var index: Int = 0
	public var open: CGFloat = 0.0
	public var high: CGFloat = 0.0
	public var low: CGFloat = 0.0
	public var close: CGFloat = 0.0
	public var volume: CGFloat = 0.0
	public var timestamp: CGFloat = 0.0
	public var desc: String {
		return "QUOTE - idx: \(index), open: \(open), high: \(high), low: \(low), close: \(close), vol: \(volume), ts: \(timestamp)"
	}
	
	public init() {}
	
	public init(_ close: CGFloat = 0.0) {
		self.close = close
	}
	
	public func update(_ values: [String: Any]) {
		self.open = values.toCGFloat("open")
		self.high = values.toCGFloat("high")
		self.low = values.toCGFloat("low")
		self.close = values.toCGFloat("close")
		self.volume = values.toCGFloat("volume")
		self.timestamp = values.toCGFloat("timestamp")
	}
	
	public func updateACM(_ values: [String: Any]) {
		self.open = values.toCGFloat("openPrice")
		self.high = values.toCGFloat("HighPrice")
		self.low = values.toCGFloat("lowPrice")
		self.close = values.toCGFloat("closePrice")
		self.timestamp = values.toCGFloat("periodStart")/1000
	}
}
