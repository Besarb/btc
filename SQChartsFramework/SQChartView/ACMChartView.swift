//
//  ACMChartView.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 14.09.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation
import UIKit
import SQChartsFramework

class ChartView: UIView {
	
	var ds: SQCDataSource
	var cv: SQCView
	var brandColor: UIColor = .blue
	
	private var btnInterval: UIButton!
	private var btnStyle: UIButton!
	private var btnSymbol: UIButton!
	
	init(dataSource: SQCDataSource, showBottomAxis: Bool = true, showLeftAxis: Bool = true, showRightAxis: Bool = true, showHGrid: Bool = true, showVGrid: Bool = true, showSelection: Bool = true) {
		self.ds = dataSource
		self.cv = SQCView(dataSource: dataSource, showBottomAxis: showBottomAxis, showLeftAxis: showLeftAxis, showRightAxis: showRightAxis, showHGrid: showHGrid, showVGrid: showVGrid, showSelection: showSelection)
		
		super.init(frame: CGRect.zero)
		
		self.btnInterval = self.makeButton(title: "1 minute") //TODO: localize
		self.btnStyle = self.makeButton(title: "Candle Sticks") //TODO: localize
		self.btnSymbol = self.makeButton(title: "???")
		
		self.btnInterval.addTarget(self, action: #selector(ChartView.actionSelectInterval), for: .touchUpInside)
		self.btnStyle.addTarget(self, action: #selector(ChartView.actionSelectStyle), for: .touchUpInside)
		self.btnSymbol.addTarget(self, action: #selector(ChartView.actionSelectSymbol), for: .touchUpInside)
	}
	
	func actionSelectInterval() {
		
	}
	
	func actionSelectStyle() {
		let actionCandleStick = UIAlertAction(title: "Candle Sticks", style: .default){ [unowned self] action in
			self.cv.change(type: .candleStick)
			self.btnStyle.setTitle("Candle Sticks", for: .normal)
		}
		
		let ac = UIAlertController(title: "Please select", message: nil, preferredStyle: .actionSheet)
	}
	
	func actionSelectSymbol() {
		
	}
	
	func makeButton(title: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
		button.titleLabel?.adjustsFontSizeToFitWidth = true
		button.titleLabel?.minimumScaleFactor = 0.6
		button.setTitle(title, for: .normal)
		button.setTitleColor(self.brandColor, for: .normal)
		button.setTitleColor(.gray, for: .disabled)
		
		self.addSubview(button)
		
		return button
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
