//
//  ChartDecoration.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 07.09.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit

class SQCAxisGrid: SQCSettingsProtocol {
	
	enum AxisType {
		case horizontal
		case vertical
	}
	
	let scrollView: UIScrollView
	let axisType: AxisType
	var lineColor: UIColor
	let lineWidth: CGFloat
	let layerName: String
	
	var pool: [SQCLayer] = []
	
	init(scrollView: UIScrollView, axisType: AxisType, lineColor: UIColor = UIColor.init(white: 0.85, alpha: 1.0), lineWidth: CGFloat = 1.0) {
		self.scrollView = scrollView
		self.axisType = axisType
		self.lineColor = lineColor
		self.lineWidth = lineWidth
		self.layerName = "ChartAxisGrid.\(self.axisType)"
	}
	
	func apply(_ settings: SQCSettings) {
		self.lineColor = settings.gridColor
	}
	
	func update(_ metricsX: SQCMetricsX?, _ metricsY: SQCMetricsY) {
		if metricsY.frameSize.height == 0 || metricsY.frameSize.width == 0 { return }
		
		switch self.axisType {
		case .horizontal:
			self.updateHorizontal(metricsY)
		case .vertical:
			guard let chartPoints = metricsX?.chartPoints else { return }
			self.updateVertical(chartPoints, metricsY)
		}
	}
	
	private func updateHorizontal(_ metricsY: SQCMetricsY) {
		let chartPoints = SQCUtils.chartPointsY(metricsY)
		var currentLayers = self.scrollView.layer.sublayers(name: self.layerName) as! [SQCLayer]
		
		while currentLayers.count > chartPoints.count {
			if let layer = currentLayers.popLast() {
				layer.removeFromSuperlayer()
				self.pool.append(layer)
			}
		}
		
		while chartPoints.count > currentLayers.count {
			let layer = self.getGridLayer()
			currentLayers.append(layer)
			self.scrollView.layer.insertSublayer(layer, at: 0)
		}
		
		for (index, layer) in currentLayers.enumerated() {
			let pointInfo = chartPoints[index]
			layer.frame = CGRect(x: metricsY.frameOffset, y: pointInfo.y, width: metricsY.frameSize.width, height: self.lineWidth)
		}
	}
	
	private func updateVertical(_ chartPoints: [SQCPoint], _ metricsY: SQCMetricsY) {
		
		let currentFrame = metricsY.drawRect
		
		// Recycle invalidLayers
		var currentLayers: [SQCLayer] = []
		let subLayers = self.scrollView.layer.sublayers(name: self.layerName) as! [SQCLayer]
		for layer in subLayers {
			if currentFrame.intersects(layer.frame) {
				currentLayers.append(layer)
			} else {
				self.pool.append(layer)
				layer.removeFromSuperlayer()
			}
		}
		currentLayers.sort(by: { $0.quoteIndex < $1.quoteIndex })
		
		// Find new points
		var newPoints: [SQCPoint] = []
		if currentLayers.count == 0 {
			for chartPoint in chartPoints {
				let rect = CGRect(x: chartPoint.x, y: 0, width: self.lineWidth, height: currentFrame.height)
				if currentFrame.contains(rect) {
					newPoints.append(chartPoint)
				}
			}
		} else {
			let lowIndex = currentLayers.first!.quoteIndex
			if lowIndex > 0 {
				for i in (0..<lowIndex).reversed() {
					let rect = CGRect(x: chartPoints[i].x, y: 0, width: self.lineWidth, height: currentFrame.height)
					if currentFrame.intersects(rect) {
						newPoints.append(chartPoints[i])
					} else {
						break
					}
				}
			}
			
			let upIndex = currentLayers.last!.quoteIndex + 1
			if upIndex < chartPoints.count {
				for i in upIndex..<chartPoints.count {
					let rect = CGRect(x: chartPoints[i].x, y: 0, width: self.lineWidth, height: currentFrame.height)
					if currentFrame.intersects(rect) {
						newPoints.append(chartPoints[i])
					} else {
						break
					}
				}
			}
		}
		
		if newPoints.count == 0 {
			return // Nothing to add, just scrolling
		}
		
		// Add layers
		for chartPoint in newPoints {
			let layer = self.getGridLayer()
			layer.quoteIndex = chartPoint.pointIndex
			layer.valueRef = chartPoint.value
			layer.frame = CGRect(x: chartPoint.point.x, y: 0.0, width: self.lineWidth, height: currentFrame.height)
			self.scrollView.layer.insertSublayer(layer, at: 0)
		}
	}
	
	func clear() {
		let sublayers = self.scrollView.layer.sublayers(name: self.layerName) as! [SQCLayer]
		let _ = sublayers.map {
			$0.removeFromSuperlayer()
		}
		self.pool.removeAll()
	}
	
	fileprivate func getGridLayer() -> SQCLayer {
		if self.pool.count > 0 {
			return self.pool.popLast()!
		}
		
		let layer = SQCLayer()
		layer.name = self.layerName
		layer.backgroundColor = self.lineColor.cgColor
		
		return layer
	}
}

public enum SQCHLineStyle {
	case dashed
	case solid
}

class SQCHLine: UIView {
	let id: String
	let value: CGFloat
	
	var containsText: Bool {
		return self.text != nil
	}
	
	private let lineStyle: SQCHLineStyle
	private let lineColor: UIColor
	private let text: String?
	private let textColor: UIColor
	private let leftMargin: CGFloat
	private var lineLayer = CAShapeLayer()

	private lazy var label = UILabel()

	init(id: String, value: CGFloat, lineStyle: SQCHLineStyle = .solid, lineColor: UIColor = .orange, text: String? = nil, textColor: UIColor = .black, leftMargin: CGFloat = 20.0) {
		self.id = id
		self.lineStyle = lineStyle
		self.lineColor = lineColor
		self.text = text
		self.textColor = textColor
		self.value = value
		self.leftMargin = leftMargin
		
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = UIColor.clear
		self.layer.addSublayer(self.lineLayer)
		
		self.buildLine()
		self.addTextLabel()
	}
	
	func update(x: CGFloat, y: CGFloat, w: CGFloat, _ forceRedraw: Bool) {
		self.x = x + self.leftMargin
		self.y = y - self.height
		
		if self.width > 0 && !forceRedraw { return }
		
		self.width = w - self.leftMargin
		if let _ = self.text {
			self.height = self.label.height
		} else {
			self.height = 1.0
		}
		self.lineLayer.frame = CGRect(x: 0, y: self.height, width: self.width, height: 1)
		
		let path = UIBezierPath()
		path.move(x: 0, y: 0.5)
		path.addLine(x: self.width, y: 0.5)
		
		self.lineLayer.path = path.cgPath
	}
	
	private func buildLine() {
		self.lineLayer.fillColor = UIColor.clear.cgColor
		self.lineLayer.lineWidth = 1.0
		self.lineLayer.lineCap = kCALineCapButt
		self.lineLayer.strokeColor = self.lineColor.cgColor
		
		if self.lineStyle == .dashed {
			self.lineLayer.lineDashPattern = [10, 5]
		}
	}
	
	private func addTextLabel() {
		guard let text = self.text else { return }
		
		self.label.text = " \(text) "
		self.label.font = UIFont.systemFont(ofSize: 10.0)
		self.label.backgroundColor = UIColor.init(white: 1.0, alpha: 0.80)
		self.label.sizeToFit()
		self.label.y = self.label.y + 1.0
		self.label.layer.borderColor = self.lineColor.cgColor
		self.label.layer.borderWidth = 1.0
		
		self.addSubview(self.label)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SQCGraphPointSelection {
	
	var graphLayer: SQCGraphLayer?
	
	private let layerName = "SQCGraphPointSelection.layerName"
	
	private var layers: [SQCLayer] = []
	private var lblInfo: UILabel?
	
	private lazy var df: DateFormatter = {
		let df = DateFormatter()
		df.locale = Locale.current
		df.timeZone = TimeZone.autoupdatingCurrent
		df.dateStyle = .medium
		df.timeStyle = .none
		return df
	}()
	private lazy var tf: DateFormatter = {
		let df = DateFormatter()
		df.locale = Locale.current
		df.timeZone = TimeZone.autoupdatingCurrent
		df.dateStyle = .none
		df.timeStyle = .medium
		return df
	}()
	
	init(_ graphLayer: SQCGraphLayer?) {
		self.graphLayer = graphLayer
	}
	
	func clear() {
		self.hideSelection()
		self.layers.removeAll()
	}
	
	func hideSelection() {
		for layer in self.layers {
			layer.removeFromSuperlayer()
		}
		self.lblInfo?.removeFromSuperview()
	}
	
	func drawSelection(at point: CGPoint, for quote: SQCQuote) {
		guard let graphLayer = self.graphLayer else { return }
		
		if !graphLayer.metrics.drawRect.contains(point) {
			self.hideSelection()
			return
		}
		
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		switch graphLayer.type {
		case .line:
			self.drawCrossSelectionLayer(at: point, for: quote, with: graphLayer)
			
		case .candleStick, .candleBars:
			self.drawLineSelectionLayer(at: point, for: quote, with: graphLayer)
			
		default:
			break
		}
		
		if graphLayer.dataSource.settings.selectionShowQuoteInfo {
			self.drawInfo(quote: quote, decimals: graphLayer.dataSource.decimals, point: point, drawRect: graphLayer.metrics.drawRect)
		}
		
		CATransaction.commit()
	}
	
	private func drawCrossSelectionLayer(at point: CGPoint, for quote: SQCQuote, with graphLayer: SQCGraphLayer) {
		if self.layers.count != 2 {
			let layerV = SQCLayer(name: self.layerName)
			layerV.backgroundColor = graphLayer.dataSource.settings.selectionColor.cgColor
			let layerH = SQCLayer(name: self.layerName)
			layerH.backgroundColor = graphLayer.dataSource.settings.selectionColor.cgColor
			
			self.clear()
			self.layers.append(layerV)
			self.layers.append(layerH)
		}
		
		let xPos: CGFloat = floor(point.x / graphLayer.metrics.xDelta) * graphLayer.metrics.xDelta
		let yPos = SQCUtils.yPos(quote.close, graphLayer.metrics)
		
		self.layers[0].frame = CGRect(x: graphLayer.metrics.frameOffset, y: yPos, width: graphLayer.metrics.frameSize.width, height: 1.0) //Horizontal
		self.layers[1].frame = CGRect(x: xPos, y: 0, width: 1.0, height: graphLayer.metrics.frameSize.height) //Vertical
		
		if self.layers[0].superlayer != graphLayer.scrollView.layer {
			graphLayer.scrollView.layer.addSublayer(self.layers[0])
		}
		if self.layers[1].superlayer != graphLayer.scrollView.layer {
			graphLayer.scrollView.layer.addSublayer(self.layers[1])
		}
	}
	
	private func drawLineSelectionLayer(at point: CGPoint, for quote: SQCQuote, with graphLayer: SQCGraphLayer) {
		if self.layers.count != 1 {
			let layer = SQCLayer(name: self.layerName)
			layer.backgroundColor = graphLayer.dataSource.settings.selectionColor.withAlphaComponent(0.3).cgColor
			layer.borderColor = graphLayer.dataSource.settings.selectionColor.cgColor
			layer.borderWidth = 1.0
			
			self.clear()
			self.layers.append(layer)
		}
		
		let xPos: CGFloat = CGFloat(quote.index) * (graphLayer.metrics.pointWidth + graphLayer.metrics.pointMargin)
		self.layers[0].frame = CGRect(x: xPos, y: -1.0, width: graphLayer.metrics.pointWidth, height: graphLayer.metrics.frameSize.height + 2.0) //Vertical
		
		if self.layers[0].superlayer != graphLayer.scrollView.layer {
			graphLayer.scrollView.layer.addSublayer(self.layers[0])
		}
	}
	
	private func drawInfo(quote: SQCQuote, decimals: Int, point: CGPoint, drawRect: CGRect) {
		guard let scrollView = self.graphLayer?.scrollView else { return }
		
		let date = Date(timeIntervalSince1970: quote.timestamp.doubleValue)
		let label = self.getLabelInfo()
		
		label.text = " O: \(quote.open.fmt(decimals: decimals)) \n H: \(quote.high.fmt(decimals: decimals)) \n L: \(quote.low.fmt(decimals: decimals)) \n C: \(quote.close.fmt(decimals: decimals)) \n \(self.df.string(from: date)) \n \(self.tf.string(from: date)) "
		label.frame = CGRect(x: 0, y: 0, width: 500, height: 300) //To avoid the label wrapping text...
		label.sizeToFit()
		
		let margin: CGFloat = 5.0
		let rect = label.frame
		
		var x: CGFloat = point.x + margin
		if x + rect.width > drawRect.maxX {
			x = point.x - rect.width - margin
		}
		var y: CGFloat = point.y - rect.height
		if y < drawRect.minY + margin {
			y = drawRect.minY + margin
		}
		
		label.x = x
		label.y = y
		
		if label.superview != scrollView {
			scrollView.addSubview(label)
		}
		scrollView.bringSubview(toFront: label)
	}
	
	private func getLabelInfo() -> UILabel {
		if let label = self.lblInfo {
			return label
		}
		
		guard let settings = self.graphLayer?.dataSource.settings else { return UILabel() }
		
		let label = UILabel()
		label.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
		label.translatesAutoresizingMaskIntoConstraints = true
		label.numberOfLines = 0
		label.layer.borderColor = settings.selectionColor.cgColor
		label.layer.borderWidth = 1.0
		label.layer.cornerRadius = 3.0
		label.layer.masksToBounds = true
		label.font = settings.selectionFont
		
		self.lblInfo = label
		
		return label
	}
}
