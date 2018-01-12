//
//  ChartAxis.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 31.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit

final class SQCAxisX: UIScrollView, SQCSettingsProtocol {
	static let preferredHeight: CGFloat = 20.0
	
	private let dataSource: SQCDataSource
	private let xAxisTag: Int = 2222
	private var pool: [SQCLabel] = []
	
	init(_ dataSource: SQCDataSource) {
		self.dataSource = dataSource
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = self.dataSource.settings.bgColor
		self.translatesAutoresizingMaskIntoConstraints = false
		self.isScrollEnabled = false
	}
	
	func apply(_ settings: SQCSettings) {
		self.backgroundColor = settings.bgColor
		self.clearLabels()
		self.pool.removeAll()
	}
	
	func update(_ contentSize: CGSize, _ offsetX: CGFloat) {
		self.contentSize = contentSize
		self.contentOffset = CGPoint(x: offsetX, y: 0)
	}
	
	func update(_ metricsX: SQCMetricsX?, _ metricsY: SQCMetricsY) {
		guard let metricsX = metricsX else { return }
		
		let currentFrame = self.visibleFrame
		//print("METRICS-X", metricsX)
		
		// Recycle invalid Labels
		var currentLabels: [SQCLabel] = []
		if let sqcLabels = self.views(withTag: self.xAxisTag) as? [SQCLabel] {
			for label in sqcLabels {
				if currentFrame.intersects(label.frame) {
					currentLabels.append(label)
				} else {
					self.pool.append(label)
					label.removeFromSuperview()
				}
			}
		}
		currentLabels.sort(by: {
			$0.chartPointIndex < $1.chartPointIndex
		})
		
		// Find new points
		var newPoints: [SQCPoint] = []
		if currentLabels.count == 0 {
			for chartPoint in metricsX.chartPoints {
				let rect = CGRect(x: chartPoint.x - 10, y: 0, width: 30, height: 10)
				if currentFrame.contains(rect) {
					newPoints.append(chartPoint)
					//print("***", "ADD", currentFrame, chartPoint.desc)
				}
			}
		} else {
			let lowIndex = currentLabels.first!.chartPointIndex
			if lowIndex > 0 {
				for i in (0..<lowIndex).reversed() {
					let rect = CGRect(x: metricsX.chartPoints[i].x - 10, y: 0, width: 30, height: 10)
					if currentFrame.intersects(rect) {
						newPoints.append(metricsX.chartPoints[i])
						//print("---", "ADD", currentFrame, metricsX.chartPoints[i].desc)
					} else {
						break
					}
				}
			}
			
			let upIndex = currentLabels.last!.chartPointIndex + 1
			if upIndex < metricsX.chartPoints.count {
				for i in upIndex..<metricsX.chartPoints.count {
					let rect = CGRect(x: metricsX.chartPoints[i].x - 10, y: 0, width: 30, height: 10)
					if currentFrame.intersects(rect) {
						newPoints.append(metricsX.chartPoints[i])
						//print("+++", "ADD", currentFrame, metricsX.chartPoints[i].desc)
					} else {
						break
					}
				}
			}
		}
		
		if newPoints.count == 0 {
			return // Nothing to add, just scrolling
		}
		
		// Add labels
		for chartPoint in newPoints {
			let label = self.getLabel()
			label.valueRef = chartPoint.value
			label.chartPointIndex = chartPoint.pointIndex
			label.text = chartPoint.valueFmt
			
			label.sizeToFit()
			label.x = ceil(chartPoint.x - label.width / 2.0)
			label.y = 4.0
			
			self.addSubview(label)
		}
	}
	
	func clearLabels() {
		let views = self.views(withTag: self.xAxisTag) as! [SQCLabel]
		let _ = views.map {
			$0.removeFromSuperview()
		}
		self.pool.removeAll()
	}
	
	private func getLabel() -> SQCLabel {
		if self.pool.count > 0 {
			return self.pool.popLast()!
		}
		
		let label = SQCLabel(self.dataSource.settings)
		label.translatesAutoresizingMaskIntoConstraints = true
		label.tag = self.xAxisTag
		
		return label
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

final class SQCAxisY: UIView, SQCSettingsProtocol {
	static let preferredWidth: CGFloat = 50.0
	
	enum DisplayType {
		case value
		case percent
	}
	
	enum AxisPosition {
		case left
		case right
	}

	private let dataSource: SQCDataSource
	private let arrowLayerWidth: CGFloat = 6.0
	
	let displayType: DisplayType
	let axisPosition: AxisPosition
	
	var showRefPrice: Bool = false
	var showCurrentPrice: Bool = true

	private var metrics: SQCMetricsY?
	private lazy var lblRefPrice: SQCLabel = {
		let settings = self.dataSource.settings
		let label = self.makeLabel(bgColor: settings.axisRefPriceBg, textColor: settings.axisRefPriceTextColor, font: settings.axisRefPriceFont)
		return label
	}()
	private lazy var lblCurrentPrice: SQCLabel = {
		let label = self.makeLabel(bgColor: UIColor(white: 0.9, alpha: 1.0), font: UIFont.boldSystemFont(ofSize: 10.0))
		return label
	}()
	
	private var pool: [SQCLabel] = []
	private var visibleLabels: [SQCLabel] = []
	private var labelHeight: CGFloat = 0
	
	init(dataSource: SQCDataSource, displayType: DisplayType = .value, axisPosition: AxisPosition = .right) {
		self.dataSource = dataSource
		self.displayType = displayType
		self.axisPosition = axisPosition
		
		super.init(frame: CGRect.zero)
		self.backgroundColor = self.dataSource.settings.bgColor
		self.translatesAutoresizingMaskIntoConstraints = false
		self.isUserInteractionEnabled = true
		
		self.labelHeight = self.dataSource.settings.axisFont.pointSize + 2.0
	}
	
	func apply(_ settings: SQCSettings) {
		self.backgroundColor = settings.bgColor
		self.lblRefPrice.backgroundColor = settings.axisRefPriceBg
		self.lblRefPrice.textColor = settings.axisRefPriceTextColor
		
		let _ = self.subviews.map({ $0.removeFromSuperview() })
		self.visibleLabels.removeAll()
		self.pool.removeAll()
	}
	
	func update(_ metrics: SQCMetricsY) {
		if self.width == 0 { return }
		self.metrics = metrics
		
		let chartPoints = SQCUtils.chartPointsY(metrics)
		
		if chartPoints.count < self.visibleLabels.count {
			for _ in chartPoints.count..<visibleLabels.count {
				let label = self.visibleLabels.popLast()!
				label.isHidden = true
				self.pool.append(label)
			}
		}
		else if chartPoints.count > visibleLabels.count {
			for _ in visibleLabels.count..<chartPoints.count {
				let label = self.getLabel()
				self.visibleLabels.append(label)
			}
		}
		
		for (index, axisInfo) in chartPoints.enumerated() {
			let label = self.visibleLabels[index]
			if label.valueRef != axisInfo.value {
				label.text = self.displayType == .value ? axisInfo.value.fmt(decimals: self.dataSource.decimals) : axisInfo.percentFmt
			}
			label.x = self.axisPosition == .left ? 0.0 : 2.0
			label.y = axisInfo.y - ceil(self.labelHeight / 2)
			label.width = self.width - 2.0
			label.height = self.labelHeight
		}
		
		self.showRefPrice(metrics)
		self.update(currentPrice: metrics.lastClosePrice)
	}
	
	func update(currentPrice: CGFloat, variation: CGFloat? = nil) {
		if !self.showCurrentPrice { return }
		guard let metrics = self.metrics else { return }
		
		if !currentPrice.between(metrics.low, metrics.high) {
			self.lblCurrentPrice.isHidden = true
			return
		}
		
		let currentPercent = (currentPrice - metrics.refPrice) / metrics.refPrice
		self.lblCurrentPrice.text = self.displayType == .value ? currentPrice.fmt(decimals: self.dataSource.decimals) : String(format: "%.2f%%", currentPercent)
		
		self.lblCurrentPrice.x = self.axisPosition == .left ? 0.0 : self.arrowLayerWidth + 2.0
		self.lblCurrentPrice.y = SQCUtils.yPos(currentPrice, metrics) - ceil(self.labelHeight / 2)
		self.lblCurrentPrice.width = self.width - self.arrowLayerWidth - 2.0
		self.lblCurrentPrice.height = self.labelHeight
		self.lblCurrentPrice.isHidden = false
		
		// Color
		if let priceVariation = variation {
			let settings = self.dataSource.settings
			var textColor: UIColor
			var bgColor: UIColor
			if priceVariation.isCloseToZero() {
				textColor = settings.axisRefPriceTextColor
				bgColor = settings.axisRefPriceBg
			} else {
				textColor = priceVariation > 0 ? settings.positive : settings.negative
				bgColor = priceVariation > 0 ? settings.positiveLight : settings.negativeLight
			}
			
			CATransaction.begin()
			CATransaction.setDisableActions(true)

			self.lblCurrentPrice.textColor = textColor
			self.lblCurrentPrice.backgroundColor = bgColor
			if let layer = self.lblCurrentPrice.layer.sublayers?.first as? CAShapeLayer {
				layer.fillColor = bgColor.cgColor
			}
			CATransaction.commit()
		}
		
		self.bringSubview(toFront: self.lblCurrentPrice)
		
		if self.lblCurrentPrice.layer.sublayers == nil || self.lblCurrentPrice.layer.sublayers?.count == 0 {
			let shapeLayer = self.arrowLayer(label: self.lblCurrentPrice)
			self.lblCurrentPrice.layer.addSublayer(shapeLayer)
		}
	}
	
	private func showRefPrice(_ metrics: SQCMetricsY) {
		if !self.showRefPrice { return }
		
		if !metrics.refPrice.between(metrics.low, metrics.high) {
			self.lblRefPrice.isHidden = true
			return
		}
		
		self.lblRefPrice.text = self.displayType == .value ? metrics.refPrice.fmt(decimals: self.dataSource.decimals) : "0.00%"
		
		self.lblRefPrice.x = self.axisPosition == .left ? 0.0 : self.arrowLayerWidth + 2.0
		self.lblRefPrice.y = SQCUtils.yPos(metrics.refPrice, metrics) - ceil(self.labelHeight / 2)
		self.lblRefPrice.width = self.width - self.arrowLayerWidth - 2.0
		self.lblRefPrice.height = self.labelHeight
		self.lblRefPrice.isHidden = false
		
		if self.lblRefPrice.layer.sublayers == nil || self.lblRefPrice.layer.sublayers?.count == 0 {
			let shapeLayer = self.arrowLayer(label: self.lblRefPrice)
			self.lblRefPrice.layer.addSublayer(shapeLayer)
		}
	}
	
	private func arrowLayer(label: UILabel) -> CAShapeLayer {
		let shapeLayer = CAShapeLayer()
		
		guard let bgColor = label.backgroundColor, bgColor != UIColor.clear else { return shapeLayer }
		
		let path = UIBezierPath()
		
		if self.axisPosition == .right {
			path.move(x: 0, y: self.labelHeight/2)
			path.addLine(x: self.arrowLayerWidth, y: 0)
			path.addLine(x: self.arrowLayerWidth, y: self.labelHeight)
			
			shapeLayer.frame = CGRect(x: -self.arrowLayerWidth, y: 0, width: self.arrowLayerWidth, height: label.height)
		} else {
			path.move(x: self.arrowLayerWidth, y: self.labelHeight/2)
			path.addLine(x: 0, y: 0)
			path.addLine(x: 0, y: self.labelHeight)
			
			shapeLayer.frame = CGRect(x: label.width, y: 0, width: self.arrowLayerWidth, height: label.height)
		}
		path.close()
		
		shapeLayer.fillColor = bgColor.cgColor
		shapeLayer.lineWidth = 1.0
		shapeLayer.path = path.cgPath
		
		return shapeLayer
	}
	
	private func getLabel() -> SQCLabel {
		if let label = self.pool.popLast() {
			label.isHidden = false
			return label
		}
		
		return self.makeLabel()
	}
	
	private func makeLabel(bgColor: UIColor? = nil, textColor: UIColor? = nil, font: UIFont? = nil) -> SQCLabel {
		let label = SQCLabel(self.dataSource.settings, useConstraints: false)
		label.textAlignment = self.axisPosition == .left ? .right : .left
		
		if bgColor != nil { label.backgroundColor = bgColor! }
		if textColor != nil { label.textColor = textColor! }
		if font != nil { label.font = font! }
		
		self.addSubview(label)
		
		return label
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

final class SQCLabel: UILabel {
	var valueRef: CGFloat = 0
	var chartPointIndex: Int = -1
	
	init(_ chartSettings: SQCSettings, useConstraints: Bool = true) {
		super.init(frame: CGRect.zero)
		
		self.translatesAutoresizingMaskIntoConstraints = !useConstraints
		self.font = chartSettings.axisFont
		self.textColor = chartSettings.axisTextColor
		self.backgroundColor = chartSettings.bgColor
		self.textAlignment = .left
		self.numberOfLines = 1
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
