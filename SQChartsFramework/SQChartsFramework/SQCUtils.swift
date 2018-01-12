//
//  ChartUtils.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 29.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation


final class SQCUtils {
	static var dateFormatter = DateFormatter() {
		didSet {
			self.dateFormatter.locale = Locale.current
			self.dateFormatter.timeZone = TimeZone.autoupdatingCurrent
		}
	}

	static func yPos(_ price: CGFloat, _ metrics: SQCMetricsY) -> CGFloat {
		return round(metrics.frameSize.height - (price - metrics.low) * metrics.frameSize.height / metrics.yDelta)
	}
	
	static func point(for price: CGFloat, index: Int, _ metrics: SQCMetricsY) -> CGPoint {
		let x = CGFloat(index) * metrics.xDelta
		let y = SQCUtils.yPos(price, metrics)
		
		return CGPoint(x: x, y: y)
	}

	static func findQuote(closeTo time: CGFloat, dataSource: SQCDataSource, _ timeLow: CGFloat, _ timeHigh: CGFloat) -> (index: Int, quote: SQCQuote?) {
		if time == timeLow {
			return (index: 0, quote: dataSource.quotes.first!);
		}
		
		if time == timeHigh {
			return (index: dataSource.lastIndex, quote: dataSource.quotes.last!);
		}
		
		let estimIndex = max(0, Int(CGFloat(dataSource.lastIndex) * (time - timeLow) / (timeHigh - timeLow)) - 10)
		
		if estimIndex < dataSource.lastIndex {
			let estimTime = dataSource.quotes[estimIndex].timestamp
			if estimTime < time {
				for i in estimIndex...dataSource.lastIndex {
					let quote = dataSource.quotes[i]
					if quote.timestamp >= time {
						return (index: i, quote: quote);
					}
				}
			}
		}
		
		return (index: -1, quote: nil)
	}
	
	static func chartPointsY(_ metrics: SQCMetricsY) -> [SQCPoint] {
		// Find rounding value
		let goldNumbers: [CGFloat] = [0.0001, 0.00025, 0.0005, 0.00075, 0.001, 0.0025, 0.005, 0.0075, 0.01, 0.1, 0.25, 0.5,
		                              1, 2, 5, 10, 15, 20, 25, 50, 100, 250, 500, 1000]
		var rounding: CGFloat = 0.0
		
		for gn in goldNumbers {
			let temp: CGFloat = floor(metrics.yDelta/gn)
			if temp <= 5.0 { //Max number of graduation lines
				rounding = gn
				break
			}
		}
		
		// Calculate Y positions
		var chartPoints: [SQCPoint] = []
		
		let margin = metrics.frameSize.height / 20.0 // Do not draw lines beyond the margin (5% of height)
		var price = rounding > metrics.low ? rounding : floor((metrics.low + rounding) * (1 / rounding)) * rounding
		var yPos = SQCUtils.yPos(price, metrics)
		var yPercent = metrics.refPrice > 0 ? (price - metrics.refPrice) / metrics.refPrice : 0
		
		while price < metrics.high {
			if yPos < (metrics.frameSize.height - margin) && yPos > margin {
				chartPoints.append(SQCPoint(value: price, percent: yPercent, pointY: yPos))
			}
			
			price += rounding
			yPos = SQCUtils.yPos(price, metrics)
			yPercent = metrics.refPrice > 0 ? (price - metrics.refPrice) / metrics.refPrice : 0
		}
		
		return chartPoints
	}
}
