//
//  ViewController.swift
//  BTC
//
//  Created by Alex Rivera on 17.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import UIKit
import UserNotifications
import SQChartsFramework

class ViewController: UITableViewController {

	private var currencies: [Any] = []
	private var positions: [Position] = []
	private var refreshTimer: Timer?
	private var footerView = OrdersFooterView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "BTC"
		self.view.backgroundColor = .bg
		
		self.tableView.separatorStyle = .none
		
		self.tableView.registerReusableCell(TableCurrencyCell.self)
		self.tableView.registerReusableCell(TableCurrencyChartCell.self)
		self.tableView.registerReusableCell(TablePositionCell.self)
		
		let btnReload = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadAll))
		self.navigationItem.setLeftBarButton(btnReload, animated: true)
		
		NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: .main){ [unowned self] notif in
			self.currencies = self.currencies.filter {
				$0 is Currency
			}
			self.tableView.reloadData()
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.updateNavButtons()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.reloadAll()
			self.fetchCurrencies()
			self.startTimer()
        }
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		self.stopTimer()
		super.viewDidDisappear(animated)
	}
	
	private func loadVisibleCurrencies() {
		self.currencies.removeAll()
		self.currencies = BTCHelper.loadVisibleCurencies()
	}
	
	private func loadSavedPositions() {
		//print("***** LOAD POSITIONS *****")
		self.positions.removeAll()
		self.positions = BTCHelper.loadPositions().sorted(by: { $0.orderId < $1.orderId })
		self.footerView.positions = self.positions
	}
	
	private func saveCurrencies() {
		self.stopTimer()
		let list: [Currency] = self.currencies.filter({ $0 is Currency }) as! [Currency]
		BTCHelper.saveVisibleCurrencies(list)
		self.startTimer()
	}
	
	@objc func reloadAll() {
		//print("***** RELOAD ALL *****")
		self.loadVisibleCurrencies()
		self.loadSavedPositions()
		self.tableView.reloadData()
	}
	
	@objc func actionEdit(sender: UIBarButtonItem) {
		self.isEditing = !self.isEditing
		self.updateNavButtons()
	}
	
	@objc func actionAddCurrency(sender: UIBarButtonItem) {
		self.isEditing = false
		
		var allSymbols = BTCHelper.symbols
		let list: [Currency] = self.currencies.filter({ $0 is Currency }) as! [Currency]
		let currentSymbols = list.map{ $0.symbol }
		
		for symbol in currentSymbols {
			if let index = allSymbols.index(of: symbol) {
				allSymbols.remove(at: index)
			}
		}
		
		let ac = UIAlertController(title: "Add currency", message: nil, preferredStyle: .actionSheet)
		for symbol in allSymbols {
			guard let title = BTCHelper.availableCurrencies[symbol]?.name else { continue }
			let action = UIAlertAction(title: title, style: .default, handler: { [unowned self] (action) in
				guard let c = BTCHelper.availableCurrencies[symbol] else { return }
				self.currencies.append(c)
				self.updateNavButtons()
				self.saveCurrencies()
				self.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: UITableViewRowAnimation.automatic)
			})
			ac.addAction(action)
		}
		let cancel = UIAlertAction(title: "Cancel", style: .cancel)
		ac.addAction(cancel)
		self.present(ac, animated: true, completion: {})
	}
	
	private func updateNavButtons() {
		let btnEdit = UIBarButtonItem(barButtonSystemItem: self.isEditing ? .done : .edit, target: self, action: #selector(actionEdit(sender:)))
		
		var buttons: [UIBarButtonItem] = []
		if self.isEditing {
			if self.currencies.count == BTCHelper.availableCurrencies.count {
				buttons = [btnEdit]
			} else {
				let btnAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(actionAddCurrency(sender:)))
				buttons = [btnEdit, btnAdd]
			}
		} else {
			buttons = [btnEdit]
		}
		
		self.navigationItem.setRightBarButtonItems(buttons, animated: true)
	}
}

//MARK: - Table datasource & Editing
extension ViewController {
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let item = self.currencies[indexPath.row]
			if item is Currency {
				let cell: TableCurrencyCell = tableView.dequeueReusableCell(indexPath: indexPath)
				cell.update(item as! Currency)
				return cell
			}
			if item is String {
				let cell: TableCurrencyChartCell = tableView.dequeueReusableCell(indexPath: indexPath)
				cell.symbol = item as! String
				return cell
			}
		}
		
		if indexPath.section == 1 {
			let cell: TablePositionCell = tableView.dequeueReusableCell(indexPath: indexPath)
			cell.update(self.positions[indexPath.row])
			return cell
		}
		
		return UITableViewCell()
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return self.currencies.count
		}
		if section == 1 {
			return self.positions.count
		}
		return 0
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 1 {
			let view = OrdersHeaderView()
			view.parentNC = self.navigationController
			return view
		}
		return nil
	}
	
	override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return section == 1 ? self.footerView : nil
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 {
			if let _ = self.currencies[indexPath.row] as? Currency {
				return 50.0
			}
			return 120.0
		}
		return 100.0
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 1 ? 45.0 : 0.0
	}
	
	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return section == 1 ? 45.0 : 0.0
	}
	
	// UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			guard let currency = self.currencies[indexPath.row] as? Currency else { return }
			let idx = IndexPath(row: indexPath.row + 1, section: 0)
			if idx.row < self.currencies.count {
				if let _ = self.currencies[idx.row] as? String {
					self.currencies.remove(at: idx.row)
					tableView.deleteRows(at: [idx], with: UITableViewRowAnimation.top)
					return
				} else {
					self.currencies.insert(currency.symbol, at: idx.row)
				}
			} else {
				self.currencies.append(currency.symbol)
			}
			tableView.insertRows(at: [idx], with: UITableViewRowAnimation.bottom)
		}
		
		if indexPath.section == 1 {
			let vc = AddItemVC()
			vc.position = self.positions[indexPath.row]
			self.navigationController?.pushViewController(vc, animated: true)
		}
	}
	
	// Editing
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle != .delete { return }
		if indexPath.section == 0 {
			self.currencies.remove(at: indexPath.row)
			if indexPath.row + 1 < self.currencies.count {
				let nextItem = self.currencies[indexPath.row + 1]
				if nextItem is String {
					self.currencies.remove(at: indexPath.row + 1)
				}
			}
			self.saveCurrencies()
			self.updateNavButtons()
		}
		if indexPath.section == 1 {
			self.positions.remove(at: indexPath.row)
			BTCHelper.savePositions(self.positions)
			self.footerView.updatePL()
		}

		tableView.deleteRows(at: [indexPath], with: .automatic)
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		if indexPath.section == 0 {
			let item = self.currencies[indexPath.row]
			return item is Currency
		}
		return true
	}
	
	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		guard sourceIndexPath.section == destinationIndexPath.section else { return }
		
		if sourceIndexPath.section == 0 {
			let tmp = self.currencies.remove(at: sourceIndexPath.row)
			self.currencies.insert(tmp, at: destinationIndexPath.row)
			self.saveCurrencies()
		}
		
		if sourceIndexPath.section == 1 {
			//OrderId is the sorting order
			let tmp = self.positions.remove(at: sourceIndexPath.row)
			self.positions.insert(tmp, at: destinationIndexPath.row)
			
			for (index, pos) in self.positions.enumerated() {
				pos.orderId = index
			}
			BTCHelper.savePositions(self.positions)
		}
	}
}

//MARK: - Timer
extension ViewController {
	private func startTimer() {
		//print("***** TIMER START *****")
		if self.refreshTimer == nil {
			self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true, block: { [weak self] (timer) in
				self?.fetchCurrencies()
			})
			self.refreshTimer?.tolerance = 1.0
		}
	}
	
	private func stopTimer() {
		//print("***** TIMER STOP *****")
		self.refreshTimer?.invalidate()
		self.refreshTimer = nil
	}
	
	private func fetchCurrencies() {
		//print("***** FETCH CURRENCIES *****")
		let list: [Currency] = self.currencies.filter({ $0 is Currency }) as! [Currency]
		for currency in list {
			currency.update()
		}
	}
}


//MARK: - Helper views
class OrdersHeaderView: UIView {
	var parentNC: UINavigationController?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.backgroundColor = .bg
		
		let viewContainer = UIComponents.view(parent: self, bgColor: .navBarBg)
		let lblTitle = UIComponents.label(parent: viewContainer, bgColor: .clear, text: "Pending Orders", textColor: .textSecondary)
		lblTitle.font = UIFont.boldSystemFont(ofSize: 13.0)
		
		let btnAdd = UIComponents.buttonUnboxed(parent: viewContainer, title: "Add", titleColor: .mainTint)
		btnAdd.addTarget(self, action: #selector(actionAdd), for: .touchUpInside)
		
		var cm = ConstraintsManager(views: ["viewContainer": viewContainer, "lblTitle": lblTitle, "btnAdd": btnAdd])
		
		cm.add("H:|[viewContainer]|")
		cm.add("V:[viewContainer(30)]|")
		cm.add("H:|-[lblTitle][btnAdd]-|")
		cm.add("V:|[lblTitle]|")
		cm.add(item: btnAdd, attribute: .centerY, relatedBy: .equal, toItem: lblTitle, attribute: .centerY)
		cm.activate()
	}
	
	@objc func actionAdd() {
		if let nc = self.parentNC {
			let vc = AddItemVC()
			nc.pushViewController(vc, animated: true)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class OrdersFooterView: UIView {
	
	var positions: [Position]?
	private var valValue: UILabel!
	private var valPL: UILabel!
	private var notifId: Any?
	private var refreshTimer: Timer?

	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.backgroundColor = .bg
		
		let contentView = UIComponents.view(parent: self, bgColor: .navBarBg)
		let lblValue = UIComponents.label(parent: contentView, bgColor: .clear, text: "Total value:", textColor: .textSecondary, fontSize: 13.0)
		let lblPL = UIComponents.label(parent: contentView, bgColor: .clear, text: "P&L:", textColor: .textSecondary, fontSize: 13.0)
		
		self.valValue = UIComponents.label(parent: contentView, bgColor: .clear, text: "-", textColor: .text)
		self.valValue.font = UIFont.boldSystemFont(ofSize: 13.0)
		
		self.valPL = UIComponents.label(parent: contentView, bgColor: .clear, text: "-", textColor: .text)
		self.valPL.font = UIFont.boldSystemFont(ofSize: 13.0)
		
		var cm = ConstraintsManager(views: ["contentView": contentView, "lblValue": lblValue, "lblPL": lblPL, "valValue": valValue, "valPL": valPL])
		
		cm.add("H:|[contentView]|")
		cm.add("V:[contentView(30)]|")
		
		cm.add(item: lblValue, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1.0, constant: 8.0)
		cm.add(item: valValue, attribute: .left, relatedBy: .equal, toItem: lblValue, attribute: .right, multiplier: 1.0, constant: 8.0)
		cm.add(item: lblPL, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 0.47, constant: 0.0)
		cm.add(item: valPL, attribute: .left, relatedBy: .equal, toItem: lblPL, attribute: .right, multiplier: 1.0, constant: 8.0)
		
		cm.add("V:|[lblValue]|")
		cm.add("V:|[valValue]|")
		cm.add("V:|[lblPL]|")
		cm.add("V:|[valPL]|")
		cm.activate()
		
		self.updateNotificationListener()
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
		
		self.notifId = NotificationCenter.default.addObserver(forName: Notification.Name(Currency.notifName), object: nil, queue: .main) { [unowned self] notif in
			self.updatePL()
		}
	}

	public func updatePL() {
		if self.refreshTimer == nil {
			self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] (timer) in
				var value: Double = 0.0
				var pl: Double = 0.0
				
				if let list = self?.positions {
					for pos in list {
						guard pos.value > 0.0 else { continue }
						value += pos.value
						pl += pos.pl
					}
				}
				
				self?.valValue.text = value.fmt(decimals: 2)
				if pl != 0 {
					self?.valPL.text = "\(pl.fmt(decimals: 2)) (\((pl/value*100).fmt(decimals: 2))%)"
					self?.valPL.textColor = pl.plColor
				}
				
				self?.refreshTimer = nil
			})
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class TableCurrencyCell: UITableViewCell {
	var currency: Currency!
	var lblCurrency: UILabel!
	var lblDate: UILabel!
	var lblChange: UILabel!
	var lblSell: UILabel!
	var viewChange: UIView!
	
	private var notifId: Any?
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.contentView.backgroundColor = .bg
		self.accessoryType = .none
		self.selectionStyle = .none
		
		let sell = UIComponents.label(parent: self.contentView, text: "Sell:", textColor: .textSecondary, fontSize: 12.0, textAlignment: .right)
		let change = UIComponents.label(parent: self.contentView, text: "Change:", textColor: .textSecondary, fontSize: 12.0, textAlignment: .right)

		self.lblCurrency = UIComponents.label(parent: self.contentView, text: "-")
		self.lblDate = UIComponents.label(parent: self.contentView, text: "-", textColor: .textSecondary)
		self.lblChange = UIComponents.label(parent: self.contentView, text: "-", textAlignment: .right)
		self.lblSell = UIComponents.label(parent: self.contentView, text: "-", textAlignment: .right)
		
		self.lblCurrency.font = UIFont.boldSystemFont(ofSize: 20.0)
		self.lblDate.font = UIFont.italicSystemFont(ofSize: 11.0)
		self.lblChange.font = UIFont.boldSystemFont(ofSize: 15.0)
		self.lblSell.font = UIFont.boldSystemFont(ofSize: 15.0)
		
		self.viewChange = UIComponents.view(parent: self.contentView, bgColor: .bg)
		
		var cm = ConstraintsManager(views: ["change": change, "sell": sell, "viewChange": viewChange,
		                                    "lblCurrency": lblCurrency, "lblDate": lblDate, "lblChange": lblChange, "lblSell": lblSell],
		                            metrics: ["viewChangeWidth": 4.0, "priceWidth": 130.0, "margin": 4.0])
		
		cm.add("H:|[viewChange(viewChangeWidth)]-[lblCurrency]-(>=10)-[sell][lblSell(priceWidth)]-|")
		cm.add("H:|[viewChange(viewChangeWidth)]-[lblDate]-(>=10)-[change][lblChange(priceWidth)]-|")
		
		cm.add("V:|[viewChange]|")
		cm.add("V:|-(margin)-[lblCurrency][lblDate(13)]-(margin)-|")
		cm.add(item: sell, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1.0, constant: -4.0)
		cm.add(item: self.lblSell, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1.0, constant: -2.0)
		
		cm.add(item: change, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1.0, constant: 4.0)
		cm.add(item: self.lblChange, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .centerY, multiplier: 1.0, constant: 2.0)
		
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
		
		self.notifId = NotificationCenter.default.addObserver(forName: Notification.Name(self.currency.symbol), object: nil, queue: .main) { [unowned self] notif in
			self.updatePrices()
		}
	}
	
	func update(_ currency: Currency) {
		self.currency = currency
		
		self.updateNotificationListener()
		
		self.lblCurrency.text = self.currency.name
		self.updatePrices()
	}
	
	private func updatePrices() {
		self.lblChange.text = "\(self.currency.change.fmt(decimals: self.currency.decimals)) (\(self.currency.changePercent.fmt(decimals: 2))%)"
		self.lblChange.textColor = self.currency.change.plColor
		self.lblSell.text = self.currency.sell.fmt(decimals: self.currency.decimals)
		self.lblDate.text = self.currency.date.fmt(style: .BothMedium)
		
		self.viewChange.backgroundColor = .bgSecondary
		UIView.animate(withDuration: 1.0, animations: {
			self.viewChange.backgroundColor = .bg
		})
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
}

class TableCurrencyChartCell: UITableViewCell {
	var symbol: String = "" {
		didSet {
			self.dataSource.decimals = symbol.uppercased() == "XRPEUR" ? 4 : 2
			self.dataSource.fetch(symbol: symbol.uppercased(), interval: 10)
			self.lblInterval.text = " \(self.dataSource.interval) min "
		}
	}
	private let dataSource = CryptoDataSource()
	private var chartView: SQCView!
	private var lblInterval: UILabel!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.contentView.backgroundColor = .bg
		self.accessoryType = .none
		self.selectionStyle = .none
		
		let settings = self.dataSource.settings
		settings.borders = [.bottom, .right]
		settings.borderColor = .bgSecondary
		settings.axisTextColor = .text
		settings.axisRefPriceTextColor = .text
		settings.gridColor = .bgSecondary
		settings.bgColor = .bg
		settings.noChange = .text

		self.chartView = SQCView(dataSource: self.dataSource, showLeftAxis: false, showSelection: false)
		self.contentView.addSubview(self.chartView)
		
		self.lblInterval = UIComponents.label(parent: self.chartView, bgColor: UIColor(white: 0.0, alpha: 0.5), text: "--", textColor: .textSecondary, textAlignment: .left)
		self.lblInterval.font = UIFont.boldSystemFont(ofSize: 11.0)
		
		var cm = ConstraintsManager(views: ["cv": self.chartView, "lblInterval": lblInterval])
		cm.add("H:|[cv]|")
		cm.add("V:|[cv]|")
		cm.add("H:|-4-[lblInterval]")
		cm.add("V:|-4-[lblInterval]")
		cm.activate()
		
		self.chartView.showCurrentPrice = false
		self.chartView.change(type: .line)
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
}

class TablePositionCell: UITableViewCell {
	
	var position: Position!
	var notifId: Any?

	var valCurrency: UILabel!
	
	var valAmount: UILabel!
	var valValue: UILabel!
	var valOpenDate: UILabel!

	var valCurrentPrice: UILabel!
	var valOpenPrice: UILabel!
	var valPL: UILabel!
	
	var viewPerf: UIView!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.contentView.backgroundColor = .bg
		self.accessoryType = .disclosureIndicator
		
		let lblOpenPrice = UIComponents.label(parent: self.contentView, text: "Open price", textColor: .textSecondary)
		let lblCurrentPrice = UIComponents.label(parent: self.contentView, text: "Curr. price", textColor: .textSecondary)
		
		let lblAmount = UIComponents.label(parent: self.contentView, text: "Amount", textColor: .textSecondary)
		let lblValue = UIComponents.label(parent: self.contentView, text: "Value", textColor: .textSecondary)

		self.valCurrency = UIComponents.label(parent: self.contentView, text: "-")
		
		self.valAmount = UIComponents.label(parent: self.contentView, text: "-")
		self.valValue = UIComponents.label(parent: self.contentView, text: "-")
		self.valOpenDate = UIComponents.label(parent: self.contentView, text: "-", textColor: .textSecondary, textAlignment: .right)
		
		self.valCurrentPrice = UIComponents.label(parent: self.contentView, text: "-")
		self.valOpenPrice = UIComponents.label(parent: self.contentView, text: "-")
		self.valPL = UIComponents.label(parent: self.contentView, text: "-")
		
		
		
		self.valCurrency.font = UIFont.boldSystemFont(ofSize: 20.0)
		self.valPL.font = UIFont.boldSystemFont(ofSize: 15.0)
		
		self.viewPerf = UIComponents.view(parent: self.contentView)
		
		var cm = ConstraintsManager(views: ["lblOpenPrice": lblOpenPrice, "lblCurrentPrice": lblCurrentPrice, "lblAmount": lblAmount, "lblValue": lblValue,
		                                    "valCurrency": valCurrency, "valAmount": valAmount, "valValue": valValue, "valOpenDate": valOpenDate,
											"valCurrentPrice": valCurrentPrice, "valOpenPrice": valOpenPrice, "valPL": valPL,
											"viewPerf": viewPerf],
		                            metrics: ["vpWidth": 4.0, "lineMargin": 2.0])
		
		cm.add("H:|[viewPerf(vpWidth)]-[valCurrency]")
		cm.add("H:|[viewPerf(vpWidth)]-[lblAmount][valAmount(lblAmount)][lblOpenPrice(lblAmount)][valOpenPrice(lblAmount)]|")
		cm.add("H:|[viewPerf(vpWidth)]-[lblValue(lblAmount)][valValue(lblAmount)][lblCurrentPrice(lblAmount)][valCurrentPrice(lblAmount)]|")
		
		cm.add("V:|-[viewPerf]-|")
		cm.add("V:|-8-[valCurrency]-(lineMargin)-[lblAmount]-(lineMargin)-[lblValue]")
		cm.add("V:|-8-[valCurrency]-(lineMargin)-[valAmount]-(lineMargin)-[valValue]")
		cm.add("V:|-8-[valOpenDate]-(lineMargin)-[lblOpenPrice]-(lineMargin)-[lblCurrentPrice]-(lineMargin)-[valPL]")
		cm.add("V:|-8-[valOpenDate]-(lineMargin)-[valOpenPrice]-(lineMargin)-[valCurrentPrice]-(lineMargin)-[valPL]")
		
		cm.add(item: valOpenDate, attribute: .left, relatedBy: .equal, toItem: lblOpenPrice, attribute: .left)
		cm.add(item: valOpenDate, attribute: .height, relatedBy: .equal, toItem: valCurrency, attribute: .height)
		cm.add(item: valPL, attribute: .left, relatedBy: .equal, toItem: lblOpenPrice, attribute: .left)
		
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
		//print(self.position.json)
		
		self.updateNotificationListener()
		guard let currency = self.position.currency else { return }
		
		self.valCurrency.text = self.position.name
		
		self.valAmount.text = self.position.amount.fmt(decimals: currency.decimals)
		self.valValue.text = self.position.value.fmt(decimals: 2)
		self.valOpenDate.text = self.position.openDate.fmt(style: DateStyle.BothShort, relative: true)
		
		self.valOpenPrice.text = self.position.openPrice.fmt(decimals: currency.decimals)
		
		self.updatePL()
	}
	
	func updatePL() {
		guard let currency = self.position.currency else { return }
		
		self.valCurrentPrice.text = currency.sell.fmt(decimals: currency.decimals)
		self.valPL.text = "\(position.pl.fmt(decimals: 2)) (\(position.plPercent.fmt(decimals: 2))%)"
		self.valPL.textColor = position.pl.plColor
		self.viewPerf.backgroundColor = position.pl.plColor
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
}
