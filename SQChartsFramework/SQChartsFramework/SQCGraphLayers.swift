//
//  GraphLayers.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 25.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit

public enum SQCGraphType: Int {
	case undefined
	case candleStick
	case candleBars
	case line
	case horizontalLines
}

protocol SQCGraphProtocol {
	var type: SQCGraphType { get }
	var minPointWidth: CGFloat { get }
	
	func clear()
	func update(_ metrics: SQCMetricsY, _ forceRedraw: Bool)
}

class SQCGraphLayer: SQCGraphProtocol, SQCSettingsProtocol {
	var type: SQCGraphType = .undefined
	var minPointWidth: CGFloat = 0.0
	var currentRange: RangeIndex = (0,0)
	var highLow: (high: CGFloat, low: CGFloat) = (0,0)
	var metrics = SQCMetricsY()
	
	let dataSource: SQCDataSource
	let scrollView: UIScrollView
	
	init(_ dataSource: SQCDataSource, _ scrollView: UIScrollView) {
		self.dataSource = dataSource
		self.scrollView = scrollView
	}
	
	func clear() {
		self.currentRange = (0,0)
		self.highLow = (0,0)
	}
	
	func update(_ metrics: SQCMetricsY, _ forceRedraw: Bool) {
		self.metrics = metrics
	}
	
	func updateLastQuote() {
		preconditionFailure("This method must be overridden")
	}
	
	func apply(_ settings: SQCSettings) {
		self.clear()
	}
	
	/// Checks if we are inside the drawed area (just scrolling) -> no need to redraw
	func checkDrawInterruption(newRange: RangeIndex, _ forceRedraw: Bool) -> Bool {
		return !forceRedraw && newRange == self.currentRange
	}
}

final class SQCGraphCandleSticks: SQCGraphSeparatePoints {
	override init(_ dataSource: SQCDataSource, _ scrollView: UIScrollView) {
		super.init(dataSource, scrollView)
		self.type = .candleStick
		self.minPointWidth = 5.0
		self.layerName = SQCCandleStickLayer.layerName
	}
	
	override func getCandle() -> SQCLayer {
		if self.pool.count > 0 {
			return self.pool.popLast()!
		}
		
		if self.dataSource.settings.useCandleBorderColor {
			return SQCCandleStickLayer(borderColor: self.dataSource.settings.candleBorderColor)
		} else {
			return SQCCandleStickLayer()
		}
	}
}

final class SQCGraphCandleBars: SQCGraphSeparatePoints {
	override init(_ dataSource: SQCDataSource, _ scrollView: UIScrollView) {
		super.init(dataSource, scrollView)
		self.type = .candleBars
		self.minPointWidth = 5.0
		self.layerName = SQCCandleBarLayer.layerName
	}
	
	override func getCandle() -> SQCLayer {
		if self.pool.count > 0 {
			return self.pool.popLast()!
		}
		
		let layer = SQCCandleBarLayer()
		return layer
	}
}

/// GraphLayer to draw separate points like candle sticks (opposed to line charts)
class SQCGraphSeparatePoints: SQCGraphLayer {
	var pool: [SQCLayer] = []
	var toRemove: [RangeIndex] = []
	var toAdd: [RangeIndex] = []
	var layerName: String = ""

	override init(_ dataSource: SQCDataSource, _ scrollView: UIScrollView) {
		super.init(dataSource, scrollView)
	}
	
	override func clear() {
		super.clear()
		self.pool.removeAll()
		self.toRemove.removeAll()
		self.toAdd.removeAll()
		let sublayers = self.scrollView.layer.sublayers(name: self.layerName)
		let _ = sublayers.map {
			$0.removeFromSuperlayer()
		}
	}
	
	override func update(_ metrics: SQCMetricsY, _ forceRedraw: Bool) {
		super.update(metrics, forceRedraw)
		
		if self.checkDrawInterruption(newRange: metrics.range, forceRedraw) { return }
		
		self.toRemove.removeAll()
		self.toAdd.removeAll()
		
		if forceRedraw || metrics.high != self.highLow.high || metrics.low != self.highLow.low {
			// Scale has changed: recycle all layers
			self.highLow = (metrics.high, metrics.low)
			toRemove = [self.currentRange]
			toAdd = [metrics.range]
		} else {
			// Remove indexes outside of the drawing area
			if self.currentRange.start < metrics.range.start {
				toRemove.append((self.currentRange.start, metrics.range.start - 1))
			}
			if self.currentRange.end > metrics.range.end {
				toRemove.append((metrics.range.end + 1, self.currentRange.end))
			}
			
			// Add new visible indexes
			if self.currentRange.start > metrics.range.start {
				toAdd.append((metrics.range.start, self.currentRange.start - 1))
			}
			if self.currentRange.end < metrics.range.end {
				toAdd.append((self.currentRange.end + 1, metrics.range.end))
			}
		}
		self.currentRange = metrics.range
		
		
		self.removeLayers()
		self.drawLayers(metrics)
		
		if self.pool.count > 5 {
			self.pool.removeLast(self.pool.count - 5)
		}
	}
	
	override func updateLastQuote() {
		guard self.dataSource.lastIndex == self.currentRange.end else { return }
		
		let currentLayers = self.scrollView.layer.sublayers(name: self.layerName) as! [SQCLayer]
		
		guard let layer = currentLayers.last else { return }
		guard let quote = self.dataSource.quotes.last else { return }
		
		if quote.high > self.highLow.high || quote.low < self.highLow.low {
			self.metrics.high = max(quote.high, self.metrics.high)
			self.metrics.low = min(quote.low, self.metrics.low)
			
			CATransaction.begin()
			CATransaction.setDisableActions(true)
			self.update(self.metrics, true)
			CATransaction.commit()

			return
		}
		
		self.update(layer, quote)
	}
	
	func removeLayers() {
		let currentLayers = self.scrollView.layer.sublayers(name: self.layerName) as! [SQCLayer]
		
		if currentLayers.count > 0 {
			for layer in currentLayers {
				for range in toRemove {
					if layer.quoteIndex >= range.start && layer.quoteIndex <= range.end {
						self.pool.append(layer)
						layer.removeFromSuperlayer()
						break
					}
				}
			}
		}
	}
	
	func drawLayers(_ metrics: SQCMetricsY) {
		// Add missing quotes
		var addQuotes: [SQCQuote] = []
		for range in toAdd {
			let rangeQuotes = self.dataSource.quotes(for: range)
			for index in rangeQuotes.indices {
				rangeQuotes[index].index = index
			}
			addQuotes.append(contentsOf: rangeQuotes)
		}
		
		// Draw the candles
		for quote in addQuotes {
			let layer = self.makeLayer(quote, metrics)
			self.scrollView.layer.addSublayer(layer)
		}
	}
	
	private func makeLayer(_ quote: SQCQuote, _ metrics: SQCMetricsY) -> SQCLayer {
		let layer = self.getCandle()
		layer.quoteIndex = quote.index
		layer.valueRef = quote.timestamp
		
		self.update(layer, quote)
		
		return layer
	}
	
	private func update(_ layer: SQCLayer, _ quote: SQCQuote) {
		let highY: CGFloat = SQCUtils.yPos(quote.high, metrics)
		let lowY: CGFloat = SQCUtils.yPos(quote.low, metrics)
		let openY: CGFloat = round(SQCUtils.yPos(quote.open, metrics) - highY)
		let closeY: CGFloat = round(SQCUtils.yPos(quote.close, metrics) - highY)
		let height: CGFloat = round(max(1.0, abs(highY - lowY)))
		
		layer.update(width: metrics.pointWidth, height: height, open: openY, close: closeY)
		layer.color = quote.close >= quote.open ? self.dataSource.settings.positive : self.dataSource.settings.negative
		
		layer.frame = CGRect(x: CGFloat(quote.index) * (metrics.pointWidth + metrics.pointMargin), y: highY, width: metrics.pointWidth, height: height)
	}
	
	func getCandle() -> SQCLayer {
		preconditionFailure("This method must be overridden")
	}
}

class SQCGraphLine: SQCGraphLayer {
	typealias PointInfo = (startPoint: CGPoint, endPoint: CGPoint)
	
	private var pointInfo: PointInfo = (CGPoint.zero, CGPoint.zero)
	private var shapeLayer = CAShapeLayer()
	private var gradientLayer = CAGradientLayer()
	private var changeColorId: Any?
	
	var showGradient: Bool = true
	var gradientColors: [Any] = []

	override init(_ dataSource: SQCDataSource, _ scrollView: UIScrollView) {
		super.init(dataSource, scrollView)
		self.type = .line
		self.minPointWidth = 1.0
		self.shapeLayer.name = "GraphLine.ShapeLayer"
		self.gradientLayer.name = "GraphLine.GradientLayer"
		
		self.shapeLayer.fillColor = UIColor.clear.cgColor
		self.shapeLayer.lineWidth = 1.0
		self.shapeLayer.lineCap = kCALineCapRound
		self.shapeLayer.lineJoin = kCALineJoinRound
		
		self.shapeLayer.addSublayer(self.gradientLayer)
		
		self.scrollView.layer.addSublayer(self.shapeLayer)
		
		if self.dataSource.settings.lineListenToPriceDirectionChange {
			self.changeColorId = NotificationCenter.default.addObserver(forName: .priceDirectionChanged, object: nil, queue: .main) { [weak self] notif in
				guard let color = notif.object as? UIColor else { return }
				guard let strongSelf = self else { return }
				strongSelf.gradientColors = [color.withAlphaComponent(0.2).cgColor, color.cgColor]
				strongSelf.shapeLayer.strokeColor = color.cgColor
				strongSelf.gradientLayer.colors = strongSelf.gradientColors
			}
		}
	}
	
	override func clear() {
		super.clear()
		self.shapeLayer.removeFromSuperlayer()
	}
	
	override func updateLastQuote() {
		guard self.dataSource.lastIndex == self.currentRange.end else {
			if let price1 = self.dataSource.quotes.first?.close, let price2 = self.dataSource.quotes.last?.close {
				let _ = self.dataSource.settings.conditionalColor(price1, price2)
			}
			return
		}
		
		guard let quote = self.dataSource.quotes.last else { return }
		
		if quote.high > self.highLow.high || quote.low < self.highLow.low {
			self.metrics.high = max(quote.high, self.metrics.high)
			self.metrics.low = min(quote.low, self.metrics.low)
		}
		
		self.update(self.metrics, true)
	}

	override func update(_ metrics: SQCMetricsY, _ forceRedraw: Bool) {
		super.update(metrics, forceRedraw)
		
		if self.checkDrawInterruption(newRange: metrics.range, forceRedraw) &&
			metrics.frameOffset >= self.pointInfo.startPoint.x && metrics.maxX <= self.pointInfo.endPoint.x ||
			(metrics.range.start == 0 && metrics.range.end == 0) { return }
		
		self.currentRange = metrics.range
		self.pointInfo = self.makePointInfo(metrics)
		
		self.shapeLayer.frame = CGRect(x: self.pointInfo.startPoint.x, y: 0, width: self.pointInfo.endPoint.x - self.pointInfo.startPoint.x, height: metrics.frameSize.height)
		
		let graphPath = UIBezierPath()
		graphPath.move(x: 0, y: self.pointInfo.startPoint.y)
		
		let startIndex = self.currentRange.start
		let endIndex = self.currentRange.end
		
		for i in (startIndex + 1)...endIndex {
			graphPath.addLine(to: SQCUtils.point(for: self.dataSource.quotes[i].close, index: (i - startIndex), metrics))
		}
		
		self.shapeLayer.path = graphPath.cgPath
		if !self.showGradient {
			self.shapeLayer.strokeColor = self.dataSource.settings.noChange.cgColor
		} else {
			var changeColor = self.dataSource.settings.positive
			if self.dataSource.settings.lineListenToPriceDirectionChange, let price1 = self.dataSource.quotes.first?.close, let price2 = self.dataSource.quotes.last?.close {
				changeColor = self.dataSource.settings.conditionalColor(price1, price2)
			}
			self.shapeLayer.strokeColor = changeColor.cgColor
			
			self.drawGradient(graphPath, changeColor)
		}
	}
	
	private func drawGradient(_ path: UIBezierPath, _ changeColor: UIColor) {
		if self.gradientColors.count != 2 {
			self.gradientColors = [changeColor.cgColor, changeColor.withAlphaComponent(0.2).cgColor]
		}
		
		let width = self.shapeLayer.frame.width
		let height = self.shapeLayer.frame.height
		
		self.gradientLayer.colors = self.gradientColors
		self.gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
		
		path.addLine(x: width, y: height)
		path.addLine(x: 0, y: height)
		path.close()
		
		let mask = CAShapeLayer()
		mask.path = path.cgPath
		
		self.gradientLayer.mask = mask
	}
	
	private func makePointInfo(_ metrics: SQCMetricsY) -> PointInfo {
		let startIndex = self.currentRange.start //max(0, self.currentRange.start)
		let endIndex = self.currentRange.end //min(self.dataSource.lastIndex, self.currentRange.end)
		
		let p1 = SQCUtils.point(for: self.dataSource.quotes[startIndex].close, index: startIndex, metrics)
		let p2 = SQCUtils.point(for: self.dataSource.quotes[endIndex].close, index: endIndex, metrics)
		
		return PointInfo(p1, p2)
	}
}

class SQCGraphHorizontalLines: SQCGraphLayer {
	var btnScaleVertical: UIButton?
	private var lines: [SQCHLine] = []
	
	override init(_ dataSource: SQCDataSource, _ scrollView: UIScrollView) {
		super.init(dataSource, scrollView)
		self.type = .horizontalLines
	}
	
	func add(id: String, value: CGFloat, lineStyle: SQCHLineStyle = .solid, lineColor: UIColor = .orange, text: String? = nil, textColor: UIColor = .black, leftMargin: CGFloat = 20.0) {
		
		let line = SQCHLine(id: id, value: value, lineStyle: lineStyle, lineColor: lineColor, text: text, textColor: textColor, leftMargin: leftMargin)
		self.lines.append(line)
		self.scrollView.addSubview(line)
	}
	
	func remove(id: String) {
		for (index, line) in self.lines.reversed().enumerated() {
			if line.id == id {
				line.removeFromSuperview()
				self.lines.remove(at: index)
			}
		}
	}
	
	override func clear() {
		super.clear()
		for line in self.lines {
			line.removeFromSuperview()
		}
		self.lines.removeAll()
	}
	
	func update(_ metrics: SQCMetricsY, _ forceRedraw: Bool, _ isVerticalScaleAdjusted: Bool) {
		let xPos = metrics.frameOffset
		let width = metrics.frameSize.width
		
		var hasLineOutside: Bool = false
		self.highLow.high = 0//metrics.high
		self.highLow.low = CGFloat(Int.max)//metrics.low
		
		for line in self.lines {
			if line.value > self.highLow.high { self.highLow.high = line.value }
			if line.value < self.highLow.low { self.highLow.low = line.value }
			
			if !line.value.between(metrics.low, metrics.high) {
				line.isHidden = true
				hasLineOutside = true
				continue
			}
			
			let yPos = SQCUtils.yPos(line.value, metrics)
			line.isHidden = false
			line.update(x: xPos, y: yPos, w: width, forceRedraw)
			
			self.scrollView.bringSubview(toFront: line)
		}
		
		if !isVerticalScaleAdjusted {
			self.btnScaleVertical?.isHidden = !hasLineOutside
		}
	}
}
