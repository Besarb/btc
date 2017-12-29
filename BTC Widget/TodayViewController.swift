//
//  TodayViewController.swift
//  BTC Widget
//
//  Created by Alex Rivera on 21.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import UIKit
import NotificationCenter

@objc (TodayViewController)

class TodayViewController: UITableViewController, NCWidgetProviding {
	
	private var currencies: [Currency] = []//BTCHelper.currencies
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.separatorStyle = .none
		self.tableView.registerReusableCell(TableCurrencyCell.self)
		
		let list: [String] = ["eth", "xrp", "ltc", "bch"]
		for symbol in list {
			guard let c = BTCHelper.currency("\(symbol)eur") else { continue }
			self.currencies.append(c)
		}
    }
	
	func actionOpenApp() {
		if let url = URL(string: "btc://") {
			extensionContext?.open(url, completionHandler: nil)
		}
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
		if activeDisplayMode == .compact {
			self.preferredContentSize = maxSize
		} else {
			self.preferredContentSize = CGSize(width: self.tableView.contentSize.width, height: self.tableView.contentSize.height + 10.0)
		}
	}
	
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		//print("WIDGET PERFORM UPDATE.")
		
		self.extensionContext?.widgetLargestAvailableDisplayMode = self.currencies.count > 2 ? .expanded : .compact
		for currency in self.currencies {
			currency.update()
		}
		
		self.tableView.reloadData()
    }
}

extension TodayViewController {
	//MARK: UITableViewDatasource
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: TableCurrencyCell = tableView.dequeueReusableCell(indexPath: indexPath)
		cell.update(self.currencies[indexPath.row])
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.currencies.count
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 25.0
	}
	
	//MARK: UITableViewDelegate
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.actionOpenApp()
	}
}

class TableCurrencyCell: UITableViewCell {
	
	private var lblCurrency: UILabel!
	private var lblSell: UILabel!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		let bgColor: UIColor = .clear
		self.contentView.backgroundColor = bgColor
		self.accessoryType = .none
		self.selectionStyle = .none
		
		self.lblCurrency = UIComponents.label(parent: self.contentView, bgColor: bgColor, text: "-", textColor: .black)
		self.lblSell = UIComponents.label(parent: self.contentView, bgColor: bgColor, text: "-", textColor: .black, textAlignment: .right)
		
		self.lblCurrency.font = UIFont.boldSystemFont(ofSize: 13.0)
		self.lblSell.font = UIFont.boldSystemFont(ofSize: 13.0)
		
		var cm = ConstraintsManager(views: ["lblCurrency": lblCurrency, "lblSell": lblSell])
		
		cm.add("H:|-[lblCurrency]-(>=10)-[lblSell]-|")
		cm.add("V:|[lblCurrency]|")
		cm.add("V:|[lblSell]|")
		
		cm.activate()
	}
	
	func update(_ currency: Currency) {
		self.lblCurrency.text = currency.name
		
		BTCRequest.fetch(symbol: currency.symbol) { (currency) in
			guard let c = currency else { return }
			self.lblSell.text = c.sell.fmt(decimals: c.decimals)
		}
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
}
