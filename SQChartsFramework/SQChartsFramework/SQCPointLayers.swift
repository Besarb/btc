//
//  PointLayers.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 25.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit

protocol SQCLayerProtocol {
	var valueRef: CGFloat { get set }
	var color: UIColor { get set }
	func update(width: CGFloat, height: CGFloat, open: CGFloat, close: CGFloat)
}

class SQCLayer: CALayer, SQCLayerProtocol {
	var quoteIndex: Int = 0
	var valueRef: CGFloat = 0.0
	var color: UIColor = .gray
	
	override init(layer: Any) {
		super.init(layer: layer)
	}
	
	convenience init(name: String? = nil) {
		self.init(layer: CALayer())
		if name != nil {
			self.name = name!
		}
	}
	
	func update(width: CGFloat, height: CGFloat, open: CGFloat, close: CGFloat) {
		fatalError("Must be overriden")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


class SQCCandleBarLayer: SQCLayer {
	static let layerName = "DCCandleBarLayer.layerName"
	
	override var color: UIColor {
		didSet {
			self.highLowLayer.backgroundColor = self.color.cgColor
			self.openLayer.backgroundColor = self.color.cgColor
			self.closeLayer.backgroundColor = self.color.cgColor
		}
	}
	
	private let highLowLayer = CALayer()
	private let openLayer = CALayer()
	private let closeLayer = CALayer()
	
	override init(layer: Any) {
		super.init(layer: layer)
	}
	
	convenience init() {
		self.init(layer: CALayer())
		self.name = SQCCandleBarLayer.layerName
		
		self.highLowLayer.backgroundColor = UIColor.black.cgColor
		self.openLayer.backgroundColor = UIColor.black.cgColor
		self.closeLayer.backgroundColor = UIColor.black.cgColor
		
		self.addSublayer(self.highLowLayer)
		self.addSublayer(self.openLayer)
		self.addSublayer(self.closeLayer)
	}
	
	override func update(width: CGFloat, height: CGFloat, open: CGFloat, close: CGFloat) {
		self.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
		
		self.highLowLayer.frame = CGRect(x: floor(width / 2.0), y: 0, width: 1.0, height: height)
		self.openLayer.frame = CGRect(x: 0, y: open, width: self.highLowLayer.frame.minX, height: 1.0)
		self.closeLayer.frame = CGRect(x: self.highLowLayer.frame.maxX, y: close, width: width - self.highLowLayer.frame.maxX, height: 1.0)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SQCCandleStickLayer: SQCLayer {
	static let layerName = "DCCandleStickLayer.layerName"
	
	override var color: UIColor {
		didSet {
			self.openCloseLayer.backgroundColor = color.cgColor
			
			if self.openCloseLayer.borderWidth == 0 {
				self.highLowLayer.backgroundColor = color.cgColor
			}
		}
	}
	
	private let highLowLayer = CALayer()
	private let openCloseLayer = CALayer()

	override init(layer: Any) {
		super.init(layer: layer)
	}
	
	convenience init() {
		self.init(layer: CALayer())
		self.name = SQCCandleStickLayer.layerName
		
		self.highLowLayer.borderColor = UIColor.black.cgColor
		
		self.addSublayer(self.highLowLayer)
		self.addSublayer(self.openCloseLayer)
	}
	
	convenience init(borderColor: UIColor) {
		self.init()
		//self.borderColor = UIColor.yellow.cgColor// borderColor.cgColor
		
		self.highLowLayer.backgroundColor = borderColor.cgColor
		self.openCloseLayer.borderColor = borderColor.cgColor
		self.openCloseLayer.borderWidth = 1.0
	}
	
	override func update(width: CGFloat, height: CGFloat, open: CGFloat, close: CGFloat) {
		self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: width, height: height)
		//self.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
		
		self.highLowLayer.frame = CGRect(x: floor(width / 2.0), y: 0, width: 1.0, height: height)
		self.openCloseLayer.frame = CGRect(x: 0, y: min(open, close), width: width, height: max(1.0, abs(open - close)))
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
