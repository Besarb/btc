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

class TablePositionCell: UITableViewCell {
	
	var position: Position!
	var notifId: Any?
	
	var lblCurrency: UILabel!
	var lblDate: UILabel!
	var lblBuyPrice: UILabel!
	var lblLastPrice: UILabel!
	var lblAmount: UILabel!
	var lblPL: UILabel!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.contentView.backgroundColor = .clear
		self.accessoryType = .none
		
		self.lblCurrency = UIComponents.label(parent: self.contentView, bgColor: .clear, text: "-", textColor: .black)
		self.lblDate = UIComponents.label(parent: self.contentView, bgColor: .clear, text: "-", textColor: .darkGray)
		self.lblBuyPrice = UIComponents.label(parent: self.contentView, bgColor: .clear, text: "-", textColor: .black, textAlignment: .right)
		self.lblLastPrice = UIComponents.label(parent: self.contentView, bgColor: .clear, text: "-", textColor: .black, textAlignment: .right)
		self.lblAmount = UIComponents.label(parent: self.contentView, bgColor: .clear, text: "-", textColor: .black, textAlignment: .right)
		self.lblPL = UIComponents.label(parent: self.contentView, bgColor: .clear, text: "-", textAlignment: .right)
		
		self.lblCurrency.font = UIFont.boldSystemFont(ofSize: 20.0)
		self.lblDate.font = UIFont.italicSystemFont(ofSize: 11.0)
		self.lblLastPrice.font = UIFont.boldSystemFont(ofSize: 15.0)
		self.lblPL.font = UIFont.boldSystemFont(ofSize: 15.0)
		
		var cm = ConstraintsManager(views: ["lblCurrency": lblCurrency, "lblDate": lblDate, "lblBuyPrice": lblBuyPrice, "lblLastPrice": lblLastPrice, "lblAmount": lblAmount, "lblPL": lblPL],
		                            metrics: ["space": 4.0, "col1": 70.0])
		
		cm.add("H:|-[lblCurrency]-(space)-[lblBuyPrice(col1)]-(space)-[lblLastPrice]-|")
		cm.add("H:|-[lblDate]-(space)-[lblAmount(col1)]-(space)-[lblPL]-|")
		
		cm.add(item: lblCurrency, attribute: .width, relatedBy: .equal, toItem: self.contentView, attribute: .width, multiplier: 0.4, constant: 0)
		cm.add(item: lblDate, attribute: .width, relatedBy: .equal, toItem: lblCurrency, attribute: .width)
		
		cm.add("V:|-(space)-[lblCurrency][lblDate]-(space)-|")
		cm.add("V:|-(space)-[lblBuyPrice][lblAmount(lblBuyPrice)]-(space)-|")
		cm.add("V:|-(space)-[lblLastPrice(lblBuyPrice)][lblPL(lblBuyPrice)]-(space)-|")
		
		cm.activate()
	}
	
	deinit {
		if let nId = self.notifId {
			NotificationCenter.default.removeObserver(nId)
		}
	}
	
	private func updateNotificationListener() {
		if let nId = self.notifId {
			NotificationCenter.default.removeObserver(nId)
		}
		
		self.notifId = NotificationCenter.default.addObserver(forName: Notification.Name(self.position.symbol), object: nil, queue: .main) { [unowned self] notif in
			self.updatePL()
		}
	}
	
	func update(_ position: Position) {
		self.position = position
		
		self.updateNotificationListener()
		guard let currency = self.position.currency else { return }
		
		self.lblCurrency.text = self.position.name
		self.lblBuyPrice.text = self.position.openPrice.fmt(decimals: currency.decimals)
		self.lblAmount.text = self.position.amount.fmt(decimals: 2)
		
		self.updatePL()
	}
	
	func updatePL() {
		//NSLog("UPDATE PL \(self.position.name)")
		guard let currency = self.position.currency else { return }
		
		self.lblDate.text = currency.date.fmt(style: .BothMedium)
		self.lblLastPrice.text = currency.sell.fmt(decimals: currency.decimals)
		self.lblPL.text = "\(position.pl.fmt(decimals: 2)) (\(position.plPercent.fmt(decimals: 2))%)"
		self.lblPL.textColor = position.pl.plColor
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
}
