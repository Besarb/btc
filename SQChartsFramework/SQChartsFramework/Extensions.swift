//
//  Extensions.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 25.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation

typealias RangeIndex = (start: Int, end: Int)

enum JsonError: Error {
	case cannotConvertToData
	case cannotConvertToDictionary
}

extension Notification.Name {
	public static let priceDirectionChanged = Notification.Name("sq.chart.framework.priceDirectionChanged")
}

extension CALayer {
	func sublayers(name: String) -> [CALayer] {
		guard let layers = self.sublayers else { return [] }
		if layers.count == 0 { return [] }
		return layers.filter { $0.name == name }
	}
}

extension UIBezierPath {
	func move(x: CGFloat, y: CGFloat) {
		self.move(to: CGPoint(x: x, y: y))
	}
	
	func addLine(x: CGFloat, y: CGFloat) {
		self.addLine(to: CGPoint(x: x, y: y))
	}
}

public extension UIView {
	public var x: CGFloat {
		get { return self.frame.origin.x }
		set { self.frame.origin.x = newValue }
	}
	
	public var y: CGFloat {
		get { return self.frame.origin.y }
		set { self.frame.origin.y = newValue }
	}
	
	public var width: CGFloat {
		get { return self.frame.width }
		set { self.frame.size.width = newValue }
	}
	
	public var height: CGFloat {
		get { return self.frame.height }
		set { self.frame.size.height = newValue }
	}
	
	public class func view(parent: UIView? = nil, bgColor: UIColor = .black) -> UIView {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = bgColor
		
		if parent != nil {
			parent!.addSubview(view)
		}
		
		return view
	}
	
	public func views(withTag tag: Int) -> [UIView] {
		return self.subviews.filter { $0.tag == tag }
	}
}

extension UIScrollView {
	var visibleFrame: CGRect {
		return CGRect(x: self.contentOffset.x, y: self.contentOffset.y,
		              width: self.bounds.width, height: self.bounds.height)
	}
}

extension Dictionary {
	func toInt(_ key: Key) -> Int {
		let val = self[key]
		if val is Int {
			return val as! Int
		}
		if let strVal = val as? String {
			return strVal.int
		}
		return 0
	}
	
	func toCGFloat(_ key: Key) -> CGFloat {
		let val = self[key]
		if val is CGFloat {
			return val as! CGFloat
		}
		if let strVal = val as? String {
			return strVal.cgFloat
		}
		return 0
	}
	
	func toDouble(_ key: Key) -> Double {
		let val = self[key]
		if val is Double {
			return val as! Double
		}
		if let strVal = val as? String {
			return strVal.double
		}
		return 0
	}
	
	func toDate(_ key: Key) -> Date {
		let val = self[key]
		if val is Date {
			return val as! Date
		}
		if let strVal = val as? String {
			return Date(timeIntervalSince1970: strVal.double)
		}
		return Date()
	}
	
	func toString(_ key: Key) -> String {
		if let strVal = self[key] as? String {
			return strVal
		}
		return ""
	}
	
	func toUrlParam(percentEncode: Bool = false) -> String {
		if self.count == 0 { return "" }
		var params = ""
		for (k, v) in self {
			if let value = v as? String {
				params += "&\(k)=\(percentEncode ? value.urlEncoded : value)"
			} else {
				params += "&\(k)=\(v)"
			}
		}
		return params
	}
	
	mutating func append<T: Any>(_ newDict: [T: Any]) {
		for (k, v) in newDict {
			let key = k as! Key
			let value = v as! Value
			self[key] = value
		}
	}
}

extension Int {
	func between(_ min: Int, _ max: Int) -> Bool {
		return min...max ~= self
	}
}

extension CGFloat {
	var doubleValue:Double { return Double(self) }
	
	func between(_ min: CGFloat, _ max: CGFloat) -> Bool {
		return min...max ~= self
	}
	
	func bounds(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
		return self.doubleValue.bounds(min.doubleValue, max.doubleValue).cgFloatValue
	}
	
	func fmtSmall() -> String {
		return self.doubleValue.fmtSmall()
	}
	
	func fmt(decimals: Int, suffix: String = "", grouping: Bool = true) -> String {
		return self.doubleValue.fmt(decimals:decimals, suffix: suffix, grouping: grouping)
	}
	
	func isCloseToZero() -> Bool {
		return abs(self) < pow(10.0, -6)
	}
}

 extension Double {
	var cgFloatValue:CGFloat { return CGFloat(self) }
	
	@nonobjc static let numFmtLocal: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .decimal
		nf.locale = Locale.current
		return nf
	}()
	
	func between(_ min: Double, _ max: Double) -> Bool {
		return min...max ~= self // self >= min && self <= max
	}
	
	func bounds(_ min: Double, _ max: Double) -> Double {
		if self > max { return max }
		if self < min { return min }
		return self
	}
	
	func fmtSmall() -> String {
		switch self {
		case _ where self >= 1000000:
			return (self/1000000.0).fmt(decimals: 2, suffix: "M")
		case _ where self >= 1000:
			return (self/1000.0).fmt(decimals: 2, suffix: "K")
		default:
			return self.fmt(decimals: 0)
		}
	}
	
	func fmt(decimals: Int, suffix: String = "", grouping: Bool = true) -> String {
		Double.numFmtLocal.usesGroupingSeparator = grouping
		Double.numFmtLocal.minimumFractionDigits = decimals
		Double.numFmtLocal.maximumFractionDigits = decimals
		
		if let result = Double.numFmtLocal.string(from: NSNumber(value: self)) {
			return "\(result)\(suffix)"
		}
		return "-"
	}
}

extension TimeInterval {
	static var minute: TimeInterval { return 60 }
	static var hour: TimeInterval { return minute * 60 }
	static var day: TimeInterval { return hour * 24 }
	static var week: TimeInterval { return day * 7 }
	static var month: TimeInterval { return day * 30 }
	static var year: TimeInterval { return month * 12 }
}

public extension String {
	public var int: Int { return Int(self) ?? 0 }
	public var int64: Int64 { return Int64(self) ?? 0 }
	public var cgFloat: CGFloat { return CGFloat(self.double) }
	public var double: Double { return Double(self) ?? 0 }
	public var length: Int { return self.count }
	
	public var urlEncoded: String {
		get {
			if let encoded = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
				return encoded
			}
			return self
		}
	}
	
	public var trim: String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	public func indexOf(_ find: String) -> Int {
		if let range = self.range(of: find) {
			return self.distance(from: self.startIndex, to: range.lowerBound)
		}
		return -1
	}
	
	public func substring(from: Int = 0, length: Int) -> String {
		let charCount = self.count
		if charCount == 0 { return "" }
		
		var posFrom = from < 0 ? 0 : from >= charCount ? charCount - 1 : from
		var posLength = abs(length)
		if length < 0 {
			posFrom = max(0, posFrom + length)
		}
		if posFrom + posLength >= charCount {
			posLength = charCount - posFrom
		}
		
		let indexFrom = self.index(self.startIndex, offsetBy: posFrom)
		let indexTo = self.index(indexFrom, offsetBy: posLength)
		
		return String(self[indexFrom..<indexTo])
	}
}

public extension Data {
	public var string: String? {
		return String(data: self, encoding: .utf8)
	}
	
	public func jsonArray<T>() -> [T] {
		guard let jsonObject = self.jsonObject() else { return [] }
		guard let json = jsonObject as? [T] else { return [] }
		return json
	}
	
	public func jsonDictionary() -> [String: Any] {
		guard let jsonObject = self.jsonObject() else { return [:] }
		guard let json = jsonObject as? [String: Any] else { return [:] }
		return json
	}
	
	public func jsonObject() -> Any? {
		do {
			let jsonObject = try JSONSerialization.jsonObject(with: self, options: .mutableContainers)
			return jsonObject
		}
		catch {
			print("DATA.JSONOBJECT ERROR: \(error.localizedDescription)")
			return nil
		}
	}
}
