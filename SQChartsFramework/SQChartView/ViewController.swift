//
//  ViewController.swift
//  SQChartView
//
//  Created by Alex Rivera on 25.08.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import UIKit
import SQChartsFramework

class ViewController: UIViewController {

	var chartType = SQCGraphType.undefined
	var btnChartType: UIButton!
	var cv: SQCView!
	
	let ds = CryptoDataSource(symbol: "LTCEUR")
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = .white
		
		self.btnChartType = self.makeButton(title: "TYPE")
		self.btnChartType.addTarget(self, action: #selector(actionChangeType), for: .touchUpInside)
		
		let btnUpdateLast = self.makeButton(title: "UpdateLast")
		btnUpdateLast.addTarget(self, action: #selector(actionUpdateLastQuote), for: .touchUpInside)
		
		let btnAddQuote = self.makeButton(title: "Add")
		btnAddQuote.addTarget(self, action: #selector(actionAddQuote), for: .touchUpInside)
		
		let btnAddOpenPriceLine	= self.makeButton(title: "RefPrice")
		btnAddOpenPriceLine.addTarget(self, action: #selector(actionAddOpenPriceLine), for: .touchUpInside)
		
		let btnAddOrdersLine	= self.makeButton(title: "Orders")
		btnAddOrdersLine.addTarget(self, action: #selector(actionAddOrderLines), for: .touchUpInside)
		
		//ACMHelper.instance.start()
		
		self.cv = SQCView(dataSource: ds, showLeftAxis: false)
		self.view.addSubview(self.cv)
		
		var cm = ConstraintsManager(views: ["cv": cv, "btnChartType": btnChartType, "btnUpdateLast": btnUpdateLast, "btnAddQuote": btnAddQuote, "btnAddOpenPriceLine": btnAddOpenPriceLine, "btnAddOrdersLine": btnAddOrdersLine])
		cm.add("H:|-10-[btnChartType]-[btnUpdateLast]-[btnAddQuote]-[btnAddOpenPriceLine]-[btnAddOrdersLine]")
		cm.add("H:|-10-[cv]-10-|")
		cm.add("V:|-20-[btnChartType]-5-[cv]-10-|")
		cm.add("V:|-20-[btnUpdateLast]-5-[cv]-10-|")
		cm.add("V:|-20-[btnAddQuote]-5-[cv]-10-|")
		cm.add("V:|-20-[btnAddOpenPriceLine]-5-[cv]-10-|")
		cm.add("V:|-20-[btnAddOrdersLine]-5-[cv]-10-|")
		cm.activate()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.actionChangeType()
		
		//ds.loadSample(fileName: "gbpusd_60s", isACM: true)
		//ds.decimals = 5
		//ds.interval = 60
		
		self.ds.fetch(interval: 10)
	}
	
	func actionChangeType() {
		switch self.chartType {
		case .candleBars, .undefined:
			self.chartType = .candleStick
			self.btnChartType.setTitle("CandleStick", for: .normal)
		case .candleStick:
			self.chartType = .line
			self.btnChartType.setTitle("Line", for: .normal)
		case .line:
			self.chartType = .candleBars
			self.btnChartType.setTitle("CandleBars", for: .normal)
		default:
			break
		}
		self.cv.change(type: self.chartType)
	}
	
	func actionUpdateLastQuote() {
		guard let lastQuote = self.ds.lastQuote() else { return }
		
		let h = lastQuote.high
		let l = lastQuote.low
		let oldC = lastQuote.close
		
		let rand = CGFloat(arc4random_uniform(100)) / 100
		var c = rand * (h - l) + l
		
		if c < l || c > h {
			c = (h + l) / 2
		}
		
		let quote = SQCQuote(c)
		quote.high = h
		quote.low = l
		quote.timestamp = lastQuote.timestamp
		
		print(quote.desc)
		
		self.cv.updateLast(quote: quote, variation: c - oldC)
	}
	
	func actionAddQuote() {
		guard let q = self.randomQuote() else { return }
		self.ds.add(q)
	}
	
	func actionAddOpenPriceLine() {
		guard let quote = self.ds.firstQuote() else {return }
		self.cv.addHLine(id: "openPrice", value: quote.close, lineStyle: .dashed, lineColor: .lightGray, leftMargin: 0)
		self.cv.showRightRefPrice = true
		//self.cv.showLeftRefPrice = true
	}
	
	func actionAddOrderLines() {
		guard let q = self.randomQuote() else { return }
		let delta = q.high - q.low
		
		self.cv.addHLine(id: "order", value: q.high + delta, lineColor: .blue, text: "Sell Limit @ \(q.close.fmt(decimals: self.ds.decimals))", textColor: .black)
		self.cv.addHLine(id: "pos", value: q.low - delta, lineColor: .orange, text: "Buy 20K @ \(q.low.fmt(decimals: self.ds.decimals))", textColor: .black)
		self.cv.refresh(true)
	}
	
	func randomQuote() -> SQCQuote? {
		guard let lastQuote = self.ds.lastQuote() else { return nil }
		
		let d = lastQuote.high - lastQuote.low
		let shift = d * random(-50, 50)
		
		let h = shift + lastQuote.high + d * random(-20, 20)
		let l = shift + lastQuote.low + d * random(-20, 20)
		let o = l + random(10, 90) * (h - l)
		let c = l + random(10, 90) * (h - l)
		
		let q = SQCQuote()
		q.open = o
		q.high = h
		q.low = l
		q.close = c
		q.volume = lastQuote.volume
		q.timestamp = lastQuote.timestamp + CGFloat(self.ds.interval)
		
		return q
	}
	
	func random(_ from: Int = 0, _ to: Int = 100) -> CGFloat {
		let rand = CGFloat(Int(arc4random_uniform(UInt32(to - from))) + from) / 100
		return rand
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func makeButton(title: String) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
		button.titleLabel?.adjustsFontSizeToFitWidth = true
		button.titleLabel?.minimumScaleFactor = 0.6
		button.setTitle(title, for: .normal)
		button.setTitleColor(.blue, for: .normal)
		button.setTitleColor(.gray, for: .disabled)
		
		self.view.addSubview(button)
		
		return button
	}
}

extension CGFloat {
	@nonobjc static let numFmtLocal: NumberFormatter = {
		let nf = NumberFormatter()
		nf.numberStyle = .decimal
		nf.locale = Locale.current
		return nf
	}()

	func fmt(decimals: Int, suffix: String = "", grouping: Bool = true) -> String {
		CGFloat.numFmtLocal.usesGroupingSeparator = grouping
		CGFloat.numFmtLocal.minimumFractionDigits = decimals
		CGFloat.numFmtLocal.maximumFractionDigits = decimals
		
		if let result = CGFloat.numFmtLocal.string(from: NSNumber(value: Double(self))) {
			return "\(result)\(suffix)"
		}
		return "-"
	}
}
