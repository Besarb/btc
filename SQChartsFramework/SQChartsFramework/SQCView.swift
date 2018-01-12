//
//  ChartView.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 25.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit

#if !DEBUG
	func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

protocol SQCViewProtocol {
	func quotesAdded(isFirstLoad: Bool)
}

public protocol SQCEvents {
	//TODO: add functions to delegate outside of framework, like pointIsSelected
	func selectedQuote(quote: SQCQuote)
}

public class SQCView: UIView {
	
	var delegate: SQCEvents?
	
	let dataSource: SQCDataSource
	let scrollView = UIScrollView()
	
	public var type: SQCGraphType {
		get {
			guard let graphLayer = self.graphLayer else { return .undefined }
			return graphLayer.type
		}
	}
	
	var graphLayer: SQCGraphLayer?
	var graphHLines: SQCGraphHorizontalLines
	var graphPointSelection: SQCGraphPointSelection?
	
	var metricsX: SQCMetricsX?
	var metricsY: SQCMetricsY?
	
	var scale: CGFloat = 1.0 {
		didSet {
			if self.scale < 1.0 {
				self.scale = 1.0
			}
			if self.scale > 300.0 {
				self.scale = 300.0
			}
		}
	}
	
	var isLastPointVisible: Bool {
		if self.scrollView.contentSize.width == 0 {
			return true
		}
		let rect = CGRect(x: self.scrollView.contentSize.width - 5, y: 0, width: 5, height: 5)
		return self.scrollView.visibleFrame.intersects(rect) || rect.minX >= self.scrollView.contentOffset.x
	}
	
	var xAxis: SQCAxisX?
	var yAxisLeft: SQCAxisY?
	var yAxisRight: SQCAxisY?

	var hGrid: SQCAxisGrid?
	var vGrid: SQCAxisGrid?
	
	public var showLeftRefPrice: Bool = false {
		didSet {
			if let yAxisLeft = self.yAxisLeft { yAxisLeft.showRefPrice = self.showLeftRefPrice }
		}
	}
	public var showRightRefPrice: Bool = false {
		didSet {
			if let yAxisRight = self.yAxisRight { yAxisRight.showRefPrice = self.showRightRefPrice }
		}
	}
	public var showCurrentPrice: Bool = true {
		didSet {
			if let yAxisRight = self.yAxisRight { yAxisRight.showCurrentPrice = self.showCurrentPrice }
		}
	}
	
	fileprivate let btnScaleVertical = UIButton(type: .custom)
	fileprivate var isVerticalScaleAdjusted: Bool = false
	fileprivate var isRefreshing: Bool = false
	

	public init(dataSource: SQCDataSource, showBottomAxis: Bool = true, showLeftAxis: Bool = true, showRightAxis: Bool = true, showHGrid: Bool = true, showVGrid: Bool = true, showSelection: Bool = true) {
		
		self.dataSource = dataSource
		self.graphHLines = SQCGraphHorizontalLines(self.dataSource, self.scrollView)
		
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = self.dataSource.settings.bgColor
		self.translatesAutoresizingMaskIntoConstraints = false
		self.contentMode = .redraw //Triggers drawRect() on rotation
		
		self.btnScaleVertical.isHidden = true
		self.btnScaleVertical.translatesAutoresizingMaskIntoConstraints = false
		self.btnScaleVertical.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
		self.btnScaleVertical.setTitle("▲▼", for: .normal)
		self.btnScaleVertical.setTitleColor(.black, for: .normal)
		self.btnScaleVertical.addTarget(self, action: #selector(SQCView.actionAdjustVerticalZoom), for: .touchUpInside)
		self.addSubview(self.btnScaleVertical)
		self.graphHLines.btnScaleVertical = self.btnScaleVertical
		
		self.dataSource.delegate = self

		self.scrollView.delegate = self
		self.scrollView.bounces = false
		self.scrollView.translatesAutoresizingMaskIntoConstraints = false
		self.scrollView.backgroundColor = self.dataSource.settings.bgColor
		self.addSubview(self.scrollView)
		
		if showHGrid {
			self.hGrid = SQCAxisGrid(scrollView: self.scrollView, axisType: .horizontal, lineColor: self.dataSource.settings.gridColor, lineWidth: self.dataSource.settings.gridLineWidth)
		}
		if showVGrid {
			self.vGrid = SQCAxisGrid(scrollView: self.scrollView, axisType: .vertical, lineColor: self.dataSource.settings.gridColor, lineWidth: self.dataSource.settings.gridLineWidth)
		}
		
		if showLeftAxis {
			self.yAxisLeft = SQCAxisY(dataSource: self.dataSource, displayType: .percent, axisPosition: .left)
			self.addSubview(self.yAxisLeft!)
			let tap = UITapGestureRecognizer(target: self, action: #selector(actionScrollToFirst))
			self.yAxisLeft?.addGestureRecognizer(tap)
		}
		if showRightAxis {
			self.yAxisRight = SQCAxisY(dataSource: self.dataSource, displayType: .value, axisPosition: .right)
			self.addSubview(self.yAxisRight!)
			let tap = UITapGestureRecognizer(target: self, action: #selector(actionScrollToLast))
			self.yAxisRight?.addGestureRecognizer(tap)
		}
		if showBottomAxis {
			self.xAxis = SQCAxisX(self.dataSource);
			self.addSubview(self.xAxis!)
		}
		
		if showSelection {
			self.enablePointSelection()
		}
		
		self.setupLayout(showBottomAxis, showLeftAxis, showRightAxis)
		self.change(type: .undefined)
	}
	
	public func change(type: SQCGraphType) {
		self.graphLayer?.clear()
		
		switch type {
		case .candleBars:
			self.graphLayer = SQCGraphCandleBars(self.dataSource, self.scrollView)
		case .candleStick:
			self.graphLayer = SQCGraphCandleSticks(self.dataSource, self.scrollView)
		case .line:
			self.graphLayer = SQCGraphLine(self.dataSource, self.scrollView)
		default:
			return
		}
		
		if let graphSelection = self.graphPointSelection {
			graphSelection.graphLayer = self.graphLayer
		}
		if let yAxisLeft = self.yAxisLeft { yAxisLeft.showRefPrice = self.showLeftRefPrice }
		if let yAxisRight = self.yAxisRight { yAxisRight.showRefPrice = self.showRightRefPrice }
		
		self.resetZoom()
	}
	
	public func resetZoom() {
		self.scrollView.contentSize = CGSize.zero
		self.scale = 1.0
		self.refresh(true)
	}
	
	public func refresh(_ forceRedraw: Bool = false) {
		guard let graphLayer = self.graphLayer else { return }
		guard self.dataSource.count > 0 else { return }
		if self.isRefreshing {
			print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", self.dataSource.symbol, self.dataSource.interval, "IS REFRESHING -> ABORT")
			return
		}
		
		self.isRefreshing = true
		
		// Adjust contentSize
		if self.scrollView.contentSize.width < self.scrollView.bounds.width {
			self.scrollView.contentSize.width = self.scrollView.bounds.width
		}
		self.scrollView.contentSize.height = self.scrollView.bounds.height
		
		// Define metrics
		let metricsY = self.dataSource.metricsY(type: .highLow, size: self.scrollView.frame.size, offset: self.scrollView.contentOffset.x, minPointWidth: graphLayer.minPointWidth, minPointMargin: 1.0, extendRangeBy: 0)
		
		if metricsY.totalContentWidth != self.scrollView.contentSize.width {
			//TODO: scale
			self.scrollView.contentSize = CGSize(width: metricsY.totalContentWidth, height: metricsY.frameSize.height)
		}
		
		//TODO: update metricsY with new bounds from indicators
		self.metricsY = metricsY
		
		if isVerticalScaleAdjusted {
			let margin: CGFloat = (max(self.metricsY!.high, self.graphHLines.highLow.high) - min(self.metricsY!.low, self.graphHLines.highLow.low)) / 20.0
			if self.graphHLines.highLow.high > self.metricsY!.high {
				self.metricsY!.high = self.graphHLines.highLow.high + margin
			}
			if self.graphHLines.highLow.low < self.metricsY!.low {
				self.metricsY!.low = self.graphHLines.highLow.low - margin
			}
		}
		
		if forceRedraw || self.metricsX == nil {
			if let hGrid = self.hGrid { hGrid.clear() }
			if let vGrid = self.vGrid { vGrid.clear() }
			if let xAxis = self.xAxis { xAxis.clearLabels() }
			self.metricsX = self.dataSource.metricsX(self.metricsY!)
		}
		
		
		// Update axis
		if let xAxis = self.xAxis { xAxis.update(self.scrollView.contentSize, self.scrollView.contentOffset.x) }
		if let yAxisLeft = self.yAxisLeft { yAxisLeft.update(self.metricsY!) }
		if let yAxisRight = self.yAxisRight { yAxisRight.update(self.metricsY!) }

		
		// Draw the graph
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		
		if let xAxis = self.xAxis { xAxis.update(self.metricsX, self.metricsY!) }
		if let hGrid = self.hGrid { hGrid.update(self.metricsX, self.metricsY!) }
		if let vGrid = self.vGrid { vGrid.update(self.metricsX, self.metricsY!) }
		
		graphLayer.update(self.metricsY!, forceRedraw)
		self.graphHLines.update(self.metricsY!, forceRedraw, isVerticalScaleAdjusted)
		
		CATransaction.commit()
		
		self.isRefreshing = false
	}
	
	public func addHLine(id: String, value: CGFloat, lineStyle: SQCHLineStyle = .solid, lineColor: UIColor = .orange, text: String? = nil, textColor: UIColor = .black, leftMargin: CGFloat = 20.0) {
		self.graphHLines.add(id: id, value: value, lineStyle: lineStyle, lineColor: lineColor, text: text, textColor: textColor, leftMargin: leftMargin)
		//self.refresh()
	}
	
	public func removeHLine(id: String) {
		self.graphHLines.remove(id: id)
		self.refresh()
	}
	
	public func removeHLines() {
		self.graphHLines.clear()
		self.refresh()
	}
	
	public func updateLast(price: CGFloat) {
		guard let lastQuote = self.dataSource.lastQuote(), price > 0 else { return }
		
		let variation = price - lastQuote.close
		if variation.isCloseToZero() { return }
		
		let quote = SQCQuote()
		quote.open = lastQuote.open
		quote.high = max(price, lastQuote.high)
		quote.low = min(price, lastQuote.low)
		quote.close = price
		quote.timestamp = lastQuote.timestamp
		
		self.updateLast(quote: quote, variation: variation)
	}
	
	public func updateLast(quote: SQCQuote, variation: CGFloat) {
		self.dataSource.updateLast(quote)
		self.graphLayer?.updateLastQuote()
		if let yAxisLeft = self.yAxisLeft { yAxisLeft.update(currentPrice: quote.close, variation: variation) }
		if let yAxisRight = self.yAxisRight { yAxisRight.update(currentPrice: quote.close, variation: variation) }
	}
	
	// MARK: ACTIONS
	
	@objc func actionAdjustVerticalZoom() {
		self.isVerticalScaleAdjusted = !self.isVerticalScaleAdjusted
		self.refresh(true)
	}

	// MARK: MISC
	public override func draw(_ rect: CGRect) {
		self.quotesAdded(isFirstLoad: false)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

//MARK: - SQCViewProtocol
extension SQCView: SQCViewProtocol {
	func quotesAdded(isFirstLoad: Bool) {
		let showLast = isFirstLoad ? true : self.isLastPointVisible
		self.refresh(true)
		if showLast {
			self.scrollToLast(animated: !isFirstLoad)
		}
	}
}

//MARK: - Point selection
extension SQCView {
	func enablePointSelection() {
		if self.graphPointSelection != nil { return }
		
		self.graphPointSelection = SQCGraphPointSelection(graphLayer)
		
		let gesture = UILongPressGestureRecognizer(target: self, action: #selector(SQCView.actionPointSelection(gesture:)))
		gesture.minimumPressDuration = 0.5
		self.scrollView.addGestureRecognizer(gesture)
	}
	
	@objc func actionPointSelection(gesture: UILongPressGestureRecognizer) {
		let point = gesture.location(in: gesture.view)
		
		switch gesture.state {
		case .began, .changed:
			if let quote = self.quote(at: point) {
				self.graphPointSelection?.drawSelection(at: point, for: quote)
				self.delegate?.selectedQuote(quote: quote)
			}
			
		default:
			self.graphPointSelection?.hideSelection()
		}
	}
	
	func quote(at point: CGPoint) -> SQCQuote? {
		guard let metrics = self.metricsY else { return nil }
		
		let xPos = point.x / metrics.xDelta
		let index = Int(floor(xPos))
		
		if index.between(metrics.range.start, metrics.range.end) {
			return self.dataSource.quotes[index]
		}
		
		return nil
	}
}

//MARK: - Scrolling
extension SQCView: UIScrollViewDelegate {
	@objc func actionScrollToFirst() {
		self.scrollToFirst(animated: true)
	}
	
	@objc func actionScrollToLast() {
		self.scrollToLast(animated: true)
	}
	
	public func scrollToFirst(animated: Bool = false) {
		self.scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
	}
	
	public func scrollToLast(animated: Bool = false) {
		//Safety check otherwise scrolling does not work
		if self.scrollView.contentSize.height == 0 {
			self.scrollView.contentSize.height = 10
		}
		
		let rect = CGRect(x: self.scrollView.contentSize.width - 1, y: 0, width: 1, height: 1)
		self.scrollView.scrollRectToVisible(rect, animated: animated)
	}
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.refresh()
	}
	
	public func scrollViewDidZoom(_ scrollView: UIScrollView) {
		//TODO: here
		print("SCROLLVIEW DID ZOOM")
	}
}

//MARK: - SQCSettingsProtocol
extension SQCView: SQCSettingsProtocol {
	public func apply(_ settings: SQCSettings) {
		self.backgroundColor = settings.bgColor
		self.scrollView.backgroundColor = settings.bgColor
		self.btnScaleVertical.setTitleColor(settings.axisTextColor, for: .normal)
		
		if let grid = self.hGrid {
			grid.apply(settings)
		}
		if let grid = self.vGrid {
			grid.apply(settings)
		}
		if let axis = self.yAxisLeft {
			axis.apply(settings)
		}
		if let axis = self.yAxisRight {
			axis.apply(settings)
		}
		if let axis = self.xAxis {
			axis.apply(settings)
		}
		
		//TODO: graphHLines
		
		self.refresh(true)
	}
}

// MARK: - Autolayout
extension SQCView {
	fileprivate func setupLayout(_ showBottomAxis: Bool, _ showLeftAxis: Bool, _ showRightAxis: Bool) {
		var views: [String: UIView] = ["scrollView" : self.scrollView]
		var format: [String: String] = [:]
		
		if let yAxisLeft = self.yAxisLeft, showLeftAxis {
			self.addViewConstraint(name: "yAxisLeft", view: yAxisLeft, size: SQCAxisY.preferredWidth, isVertical: true, views: &views, format: &format)
		}
		if let yAxisRight = self.yAxisRight, showRightAxis {
			self.addViewConstraint(name: "yAxisRight", view: yAxisRight, size: SQCAxisY.preferredWidth + 10, isVertical: true, views: &views, format: &format)
		}
		if let xAxis = self.xAxis, showBottomAxis {
			self.addViewConstraint(name: "xAxis", view: xAxis, size: SQCAxisX.preferredHeight, isVertical: false, views: &views, format: &format)
		}
		
		let borders = self.dataSource.settings.borders
		if borders.contains(.left) {
			self.addBorderConstraint(name: "leftBorderView", isVertical: true, views: &views, format: &format)
		}
		if borders.contains(.right) {
			self.addBorderConstraint(name: "rightBorderView", isVertical: true, views: &views, format: &format)
		}
		if borders.contains(.top) {
			self.addBorderConstraint(name: "topBorderView", isVertical: false, views: &views, format: &format)
		}
		if borders.contains(.bottom) {
			self.addBorderConstraint(name: "bottomBorderView", isVertical: false, views: &views, format: &format)
		}
		
		let hFormat = "H:|\(format.toString("yAxisLeft"))\(format.toString("leftBorderView"))[scrollView]\(format.toString("rightBorderView"))\(format.toString("yAxisRight"))|"
		let vFormat = "V:|\(format.toString("topBorderView"))[scrollView]\(format.toString("bottomBorderView"))\(format.toString("xAxis"))|"
		
		self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: hFormat, options: [], metrics: nil, views: views))
		self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: vFormat, options: [], metrics: nil, views: views))
		
		self.addConstraint(NSLayoutConstraint(item: self.btnScaleVertical, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1, constant: 5))
		self.addConstraint(NSLayoutConstraint(item: self.btnScaleVertical, attribute: .left, relatedBy: .equal, toItem: self.scrollView, attribute: .left, multiplier: 1, constant: 10))
		self.bringSubview(toFront: self.btnScaleVertical)
	}
	
	private func addBorderConstraint(name: String, isVertical: Bool, views: inout [String: UIView], format: inout [String: String]) {
		let borderView = UIView.view(parent: self, bgColor: self.dataSource.settings.borderColor)
		self.addViewConstraint(name: name, view: borderView, size: self.dataSource.settings.borderWidth, isVertical: isVertical, views: &views, format: &format)
	}
	
	private func addViewConstraint(name: String, view: UIView, size: CGFloat, isVertical: Bool, views: inout [String: UIView], format: inout [String: String]) {
		views.append([name: view])
		format[name] = "[\(name)(\(size))]"
		if isVertical {
			self.addVConstraint(view: view)
		} else {
			self.addHConstraint(view: view)
		}
	}
	
	private func addVConstraint(view: UIView) {
		self.addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.scrollView, attribute: .top, multiplier: 1, constant: 0))
		self.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: self.scrollView, attribute: .height, multiplier: 1, constant: 0))
	}
	
	private func addHConstraint(view: UIView) {
		self.addConstraint(NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self.scrollView, attribute: .left, multiplier: 1, constant: 0))
		self.addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: self.scrollView, attribute: .width, multiplier: 1, constant: 0))
	}
}
