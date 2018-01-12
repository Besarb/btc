//
//  Extensions.swift
//  BTC
//
//  Created by Alex Rivera on 18.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import Foundation
import UIKit

public extension Notification.Name {
	public static let priceUpdate = Notification.Name("btc.notification.price.update")
}

protocol Reusable: class {
	static var reuseIdentifier: String { get }
}

extension Reusable {
	static var reuseIdentifier: String { return String(describing: self) }
}

extension UITableViewCell: Reusable {}

extension UITableView {
	func registerReusableCell<T: UITableViewCell>(_: T.Type) {
		self.register(T.self, forCellReuseIdentifier: String(describing: T.reuseIdentifier))
	}
	
	func registerReusableHeaderFooterView<T: UITableViewHeaderFooterView>(_: T.Type) where T: Reusable {
		self.register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
	}
	
	func dequeueReusableCell<T: UITableViewCell>(indexPath: IndexPath) -> T {
		guard let cell = self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
			fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
		}
		return cell
	}
	
	func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T? where T: Reusable {
		guard let cell = self.dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
			print("Could not dequeue headerFooterView with identifier: \(T.reuseIdentifier)")
			return nil
		}
		return cell
	}
}

public extension UIView {
	
	/// Randomly colors the background of all subviews.
	func colorSubViews() {
		let subviews = self.subviews
		
		for (index, subview) in subviews.enumerated() {
			let hue: CGFloat = 1.0 / CGFloat(subviews.count) * CGFloat(index)
			subview.backgroundColor = UIColor.init(hue: hue, saturation: 0.5, brightness: 1.0, alpha: 1.0)
		}
	}
}

public extension Dictionary {
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
		if let dblVal = val as? Double {
			return Date(timeIntervalSince1970: dblVal)
		}
		return Date()
	}
	
	func toString(_ key: Key) -> String {
		if let strVal = self[key] as? String {
			return strVal
		}
		return ""
	}
}

extension Data {
	func jsonArray<T>() -> [T] {
		guard let jsonObject = self.jsonObject() else { return [] }
		guard let json = jsonObject as? [T] else { return [] }
		return json
	}
	
	func jsonDictionary() -> [String: Any] {
		guard let jsonObject = self.jsonObject() else { return [:] }
		guard let json = jsonObject as? [String: Any] else { return [:] }
		return json
	}
	
	func jsonObject() -> Any? {
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

public extension String {
	var int: Int { return Int(self) ?? 0 }
	var int64: Int64 { return Int64(self) ?? 0 }
	var double: Double { return Double(self) ?? 0 }
	var length: Int { return self.count }
	
	var urlEncoded: String {
		get {
			if let encoded = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
				return encoded
			}
			return self
		}
	}
	var trim: String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	func indexOf(_ find: String) -> Int {
		if let range = self.range(of: find) {
			return self.distance(from: self.startIndex, to: range.lowerBound)
		}
		return -1
	}
	
	func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
		
		return boundingBox.height
	}
}

public extension Double {
	@nonobjc static let numFmtLocal: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .decimal
		nf.locale = Locale.current
		return nf
	}()
	
	/// Rounds the double to decimal places value
	func roundTo(decimals:Int) -> Double {
		let divisor = pow(10.0, Double(decimals))
		return (self * divisor).rounded() / divisor
	}
	
	/// Rounds the double to 2 decimals if > 1000, otherwise 0. Adds suffix "M" (millions) or "K" (thousands) accordingly.
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
		Double.numFmtLocal.minimumFractionDigits = 2
		Double.numFmtLocal.maximumFractionDigits = decimals
		
		if let result = Double.numFmtLocal.string(from: NSNumber(value: self)) {
			return "\(result)\(suffix)"
		}
		return "-"
	}
	
	func bounds(min: Double, max: Double) -> Double {
		if self < min { return min }
		if self > max { return max }
		return self
	}
	
	func isCloseToZero() -> Bool {
		return abs(self) < pow(10.0, -6)
	}
	
	func isCloseTo(double value:Double) -> Bool {
		return abs(self - value) < pow(10.0, -6)
	}
	
	var plColor: UIColor {
		if self > 0.0 { return UIColor.positive }
		if self < 0.0 { return UIColor.negative }
		return UIColor.text
	}
}

public extension Int {
	var doubleValue:Double { return Double(self) }
	var int32Value:Int32 { return Int32(self) }
	var isOdd: Bool { return self % 2 == 0 }
	
	func fmtSmall() -> String {
		return self.doubleValue.fmtSmall()
	}
	
	func fmt(decimals: Int, suffix: String = "", grouping: Bool = true) -> String {
		return self.doubleValue.fmt(decimals: decimals, suffix: suffix, grouping: grouping)
	}
	
	func bounds(min: Int, max: Int) -> Int {
		return Int(self.doubleValue.bounds(min: min.doubleValue, max: max.doubleValue))
	}
}

public enum DateStyle {
	case DateMedium
	case DateMediumTimeShort
	case DateShort
	case DateShortTimeMedium
	case TimeMedium
	case TimeShort
	case BothShort
	case BothMedium
}

public extension Date {
	static var oneDay: TimeInterval { return 60 * 60 * 24 }
	static var now: Int64 {
		return Int64(self.timeIntervalSinceReferenceDate * 1000)
	}
	
	func fmt(format: String, relative: Bool = false, formatterType: DateFormatterType = .Local) -> String {
		let df = DateFormatter.dateFormatter(type: formatterType)
		df.doesRelativeDateFormatting = relative
		df.dateFormat = format
		return df.string(from: self)
	}
	
	func fmt(style: DateStyle, relative: Bool = true, formatterType: DateFormatterType = .Local) -> String {
		let df = DateFormatter.dateFormatter(type: formatterType)
		df.doesRelativeDateFormatting = relative
		
		switch style {
		case .DateMedium:
			df.dateStyle = .medium
			df.timeStyle = .none
		case .DateMediumTimeShort:
			df.dateStyle = .medium
			df.timeStyle = .short
		case .DateShort:
			df.dateStyle = .short
			df.timeStyle = .none
		case .DateShortTimeMedium:
			df.dateStyle = .short
			df.timeStyle = .medium
		case .TimeMedium:
			df.dateStyle = .none
			df.timeStyle = .medium
		case .TimeShort:
			df.dateStyle = .none
			df.timeStyle = .short
		case .BothShort:
			df.dateStyle = .short
			df.timeStyle = .short
		case .BothMedium:
			df.dateStyle = .medium
			df.timeStyle = .medium
		}
		
		return df.string(from: self)
	}
}

public enum DateFormatterType: Int {
	case Local
	case UTC
}

public extension DateFormatter {
	@nonobjc static var cache = [Int: DateFormatter]()
	
	class func dateFormatter(type: DateFormatterType) -> DateFormatter {
		if let df = DateFormatter.cache[type.rawValue] {
			return df
		}
		else {
			let df = DateFormatter()
			df.locale = Locale.current
			
			switch type {
			case .Local:
				break
				
			case .UTC:
				df.dateFormat = "yyyyMMdd'T'HH:mm:ss"
				df.timeZone = TimeZone(secondsFromGMT: 0)
			}
			
			DateFormatter.cache[type.rawValue] = df
			return df
		}
	}
}

public extension UIColor {
	class var mainTint: UIColor { get { return UIColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0) } }
	class var navBarBg: UIColor { get { return UIColor(white: 0.15, alpha: 1.0) } }
	
	class var bg: UIColor { get { return UIColor.black } }
	class var bgSecondary: UIColor { get { return UIColor(white: 0.15, alpha: 1.0) } }
	class var text: UIColor { get { return UIColor.white } }
	class var textSecondary: UIColor { get { return UIColor.lightGray } }
	
	class var positive: UIColor { get { return UIColor(red: 0.3, green: 1, blue: 0.3, alpha: 1.0) } }
	class var negative: UIColor { get { return UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1.0) } }
	
	class var headerBg: UIColor { get { return .black } }
	class var headerText: UIColor { get { return .white } }
	class var headerTextSecondary: UIColor { get { return .lightGray } }
	
	class var buy: UIColor { get { return UIColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0) } }
	class var buySecondary: UIColor { get { return UIColor(red: 0.7, green: 0.4, blue: 0.4, alpha: 1.0) } }
	class var sell: UIColor { get { return UIColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1.0) } }
	class var sellSecondary: UIColor { get { return UIColor(red: 0.4, green: 0.4, blue: 0.7, alpha: 1.0) } }
//	class var buy: UIColor { get { return UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0) } }
//	class var buySecondary: UIColor { get { return UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0) } }
//	class var sell: UIColor { get { return UIColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0) } }
//	class var sellSecondary: UIColor { get { return UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0) } }
}

public extension UIDevice {
	class var isIPhone: Bool {
		return UIDevice.current.userInterfaceIdiom == .phone
	}
	
	class var isIPad: Bool {
		return UIDevice.current.userInterfaceIdiom == .pad
	}
	
	class var isSimulator: Bool {
		return UIDevice.name == "Simulator"
	}
	
	class var name: String {
		return UIDevice.current.modelName
	}
	
	class var nameEscaped: String {
		if let name = UIDevice.current.modelName.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
			return name
		}
		return "undefined"
	}
	
	var modelId: String {
		get {
			var systemInfo = utsname()
			uname(&systemInfo)
			let machineMirror = Mirror(reflecting: systemInfo.machine)
			let identifier = machineMirror.children.reduce("") { identifier, element in
				guard let value = element.value as? Int8, value != 0 else { return identifier }
				return identifier + String(UnicodeScalar(UInt8(value)))
			}
			return identifier
		}
	}
	
	var modelName: String {
		get {
			let identifier = UIDevice.current.modelId
			switch identifier {
			case "iPod5,1":                                 return "iPod Touch 5"
			case "iPod7,1":                                 return "iPod Touch 6"
			case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
			case "iPhone4,1":                               return "iPhone 4s"
			case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
			case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
			case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
			case "iPhone7,2":                               return "iPhone 6"
			case "iPhone7,1":                               return "iPhone 6 Plus"
			case "iPhone8,1":                               return "iPhone 6s"
			case "iPhone8,2":                               return "iPhone 6s Plus"
			case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
			case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
			case "iPhone8,4":                               return "iPhone SE"
			case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
			case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
			case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
			case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
			case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
			case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
			case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
			case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
			case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
			case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
			case "AppleTV5,3":                              return "Apple TV"
			case "i386", "x86_64":                          return "Simulator"
			default:                                        return identifier
			}
		}
	}
}
