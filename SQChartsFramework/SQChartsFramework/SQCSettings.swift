//
//  ChartSettings.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 29.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation

protocol SQCSettingsProtocol {
	func apply(_ settings: SQCSettings)
}

public class SQCSettings {
	public struct Borders: OptionSet {
		public let rawValue: Int
		public static let left = Borders(rawValue: 1 << 0)
		public static let top = Borders(rawValue: 1 << 1)
		public static let right = Borders(rawValue: 1 << 2)
		public static let bottom = Borders(rawValue: 1 << 3)
		
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
	}
	
	public var maxPointsCount: Int = 0 //'0' means no maximum
	public var displayAllPoints = true //When possible -> will try to stretch the chart so it is visible in one screen
	
	// Borders
	public var borders: Borders = [.left, .top, .right, .bottom]
	public var borderColor: UIColor = UIColor(white: 0.8, alpha: 1.0)
	public var borderWidth: CGFloat = 1.0
	
	// Axis
	public var axisFont = UIFont.systemFont(ofSize: 10.0)
	public var axisTextColor = UIColor.black
	public var axisRefPriceBg = UIColor(white: 0.9, alpha: 1.0)
	public var axisRefPriceTextColor = UIColor.black
	public var axisRefPriceFont = UIFont.boldSystemFont(ofSize: 10.0)
	
	// Selection
	public var selectionFont = UIFont.systemFont(ofSize: 10.0)
	public var selectionColor: UIColor = UIColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0)
	public var selectionShowQuoteInfo: Bool = true
	
	// Grid
	public var gridColor = UIColor(white: 0.9, alpha: 1.0)
	public var gridLineWidth: CGFloat = 1.0
	
	// Line
	public var lineListenToPriceDirectionChange: Bool = false
	
	// Candle Sticks
	public var candleBorderColor: UIColor = .clear
	public var useCandleBorderColor: Bool { return self.candleBorderColor != .clear }
	
	// Colors
	public var bgColor: UIColor = .white
	public var priceDirection: Int = 0
	public var noChange: UIColor = .black
	public var positive: UIColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
	public var positiveLight: UIColor = UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0)
	public var negative: UIColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
	public var negativeLight: UIColor = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
	public var positionColor: UIColor = .orange
	public var orderColor: UIColor = .blue

	public func conditionalColor(_ price1: CGFloat = 0, _ price2: CGFloat) -> UIColor {
		var tmpPriceDirection: Int = 0
		if price1 == price2 {
			tmpPriceDirection = 0
		} else {
			tmpPriceDirection = price2 > price1 ? 1 : -1
		}
		
		var color: UIColor = self.noChange
		switch tmpPriceDirection {
		case 1:
			color = self.positive
		case -1:
			color = self.negative
		default:
			break
		}
		
		if tmpPriceDirection != self.priceDirection {
			NotificationCenter.default.post(name: .priceDirectionChanged, object: color)
		}
		self.priceDirection = tmpPriceDirection
		
		return color
	}
}
