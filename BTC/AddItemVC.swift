//
//  AddItemVC.swift
//  BTC
//
//  Created by Alex Rivera on 18.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import Foundation
import UIKit

class AddItemVC: UIViewController {
	
	var position = Position(json: [:])
	
	fileprivate var currentTextField: UITextField?
	
	fileprivate var btnCurrency: UIButton!
	fileprivate var lblOrderId: UILabel!
	fileprivate var txtAmount: UITextField!
	fileprivate var txtOpenPrice: UITextField!
	fileprivate var datePicker = UIDatePicker()
	fileprivate var btnSave: UIButton!

	fileprivate var currency: Currency = BTCHelper.currencies[0]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = .bg
		
		let lblCurrency = UIComponents.label(parent: self.view, text: "Currency", textColor: .textSecondary)
		let lblOrder  = UIComponents.label(parent: self.view, text: "Order ID", textColor: .textSecondary)
		let lblAmount   = UIComponents.label(parent: self.view, text: "Amount", textColor: .textSecondary)
		let lblBuyPrice = UIComponents.label(parent: self.view, text: "Buy price", textColor: .textSecondary)
		let lblOpenDate = UIComponents.label(parent: self.view, text: "Open date", textColor: .textSecondary)
		
		self.btnCurrency = UIComponents.buttonUnboxed(parent: self.view, title: self.currency.name, titleColor: .mainTint)
		self.lblOrderId  = UIComponents.label(parent: self.view)
		self.txtAmount   = UIComponents.textField(parent: self.view, keyboardType: .decimalPad)
		self.txtOpenPrice = UIComponents.textField(parent: self.view, keyboardType: .decimalPad)
		
		self.view.addSubview(self.datePicker)
		self.datePicker.translatesAutoresizingMaskIntoConstraints = false
		self.datePicker.datePickerMode = .dateAndTime
		self.datePicker.setValue(UIColor.text, forKey: "textColor")
		
		self.txtAmount.delegate = self
		self.txtOpenPrice.delegate = self
		
		self.btnCurrency.addTarget(self, action: #selector(actionSelectCurrency), for: .touchUpInside)
		self.btnSave = UIComponents.buttonBoxed(parent: self.view, title: "SAVE", titleColor: .white, bgColor: .red)
		self.btnSave.addTarget(self, action: #selector(actionSave), for: .touchUpInside)
		
		
		var cm = ConstraintsManager(views: ["lblCurrency": lblCurrency, "lblOrder": lblOrder, "lblAmount": lblAmount, "lblBuyPrice": lblBuyPrice, "lblOpenDate": lblOpenDate,
											"btnCurrency": btnCurrency, "lblOrderId": lblOrderId, "txtAmount": txtAmount, "txtOpenPrice": txtOpenPrice, "datePicker": datePicker, "btnSave": btnSave],
		                            metrics: ["topMargin": 20.0, "rowHeight": 30.0])
		
		cm.add("H:|-[lblCurrency][btnCurrency(lblCurrency)]-|")
		cm.add("H:|-[lblOrder][lblOrderId(lblCurrency)]-|")
		cm.add("H:|-[lblAmount][txtAmount(lblCurrency)]-|")
		cm.add("H:|-[lblBuyPrice][txtOpenPrice(lblCurrency)]-|")
		cm.add("H:|-[lblOpenDate]-|")
		cm.add("H:|-[datePicker]-|")
		cm.add("H:|-[btnSave]-|")
		
		cm.add("V:|-(topMargin)-[lblCurrency(rowHeight)]-[lblOrderId(rowHeight)]-[lblAmount(rowHeight)]-[lblBuyPrice(rowHeight)]-[lblOpenDate(rowHeight)][datePicker]-30-[btnSave(40)]")
		cm.add(item: btnCurrency, attribute: .centerY, relatedBy: .equal, toItem: lblCurrency, attribute: .centerY)
		cm.add(item: lblOrderId, attribute: .centerY, relatedBy: .equal, toItem: lblOrder, attribute: .centerY)
		cm.add(item: txtAmount, attribute: .centerY, relatedBy: .equal, toItem: lblAmount, attribute: .centerY)
		cm.add(item: txtOpenPrice, attribute: .centerY, relatedBy: .equal, toItem: lblBuyPrice, attribute: .centerY)
		
		cm.activate()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print(self.position.json)
		if self.position.orderId == 0 {
			self.position.orderId = self.getNextOrderId()
		}
		
		self.title = self.position.openPrice == 0 ? "Add new item" : "Edit item"
		self.datePicker.maximumDate = Date()

		if let c = self.position.currency {
			self.currency = c
			self.btnCurrency.setTitle(self.currency.name, for: .normal)
		}
		
		self.lblOrderId.text = self.position.orderId.fmt(decimals: 0, grouping: false)
		self.txtAmount.text = self.position.amount.fmt(decimals: self.currency.decimals, grouping: false)
		self.txtOpenPrice.text = self.position.openPrice.fmt(decimals: self.currency.decimals, grouping: false)
		self.datePicker.date = self.position.openDate
		
		self.addActionToolbarButton()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	func addActionToolbarButton() {
		let button = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionDelete))
		self.navigationItem.setRightBarButton(button, animated: true)
	}
	
	private func getNextOrderId() -> Int {
		let positions: [Position] = BTCHelper.loadPositions()
		if positions.count == 0 {
			return 1
		} else {
			let ids = positions.map{ $0.orderId }
			if let maxId = ids.max() {
				return maxId + 1
			} else {
				return positions.count + 1
			}
		}
	}
	
	private func buildPosition() -> Position {
		let pos = Position(json: [:])
		
		if let orderId = self.lblOrderId.text {
			pos.orderId = orderId.int
		}
		if let amount = self.txtAmount.text {
			pos.amount = amount.double
		}
		if let price = self.txtOpenPrice.text {
			pos.openPrice = price.double
		}
		
		pos.openDate = self.datePicker.date
		pos.currency = self.currency
		if pos.orderId <= 0 {
			pos.orderId = self.getNextOrderId()
		}
		
		print(pos.json)
		return pos
	}
	
	@objc func actionSave() {
		let pos = self.buildPosition()
		
		if pos.isValid {
			BTCHelper.appendPosition(pos)
		}
		
		let action = UIAlertAction(title: "Continue", style: .default, handler: { [weak self] action in
			self?.navigationController?.popViewController(animated: true)
		})
		let ac = UIAlertController(title: "Done!", message: nil, preferredStyle: .alert)
		ac.addAction(action)
		self.present(ac, animated: true, completion: nil)
	}
	
	@objc func actionDelete() {
		let actionDelete = UIAlertAction(title: "Delete", style: .destructive) { [unowned self] action in
			let pos = self.buildPosition()
			if pos.isValid {
				BTCHelper.deletePosition(self.position)
			}
			self.navigationController?.popViewController(animated: true)
		}
		let actionArchive = UIAlertAction(title: "Archive", style: .default) { [unowned self] action in
			//let pos = self.buildPosition()
			
			//TODO: enter closePrice & closeDate
			self.navigationController?.popViewController(animated: true)
		}
		let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		
		let ac = UIAlertController(title: "Choose action", message: nil, preferredStyle: .actionSheet)
		ac.addAction(actionDelete)
		ac.addAction(actionArchive)
		ac.addAction(actionCancel)
		
		self.present(ac, animated: true, completion: {})
	}
	
	@objc func actionDone() {
		if let textField = self.currentTextField {
			textField.resignFirstResponder()
		}
		self.addActionToolbarButton()
	}
	
	@objc func actionSelectCurrency() {
		let ac = UIAlertController(title: "Select the currency", message: nil, preferredStyle: .actionSheet)
		
		let currencies = BTCHelper.currencies
		for currency in currencies {
			let action = UIAlertAction(title: currency.name, style: .default) { [unowned self] action in
				self.currency = currency
				self.btnCurrency.setTitle(self.currency.name, for: .normal)
			}
			ac.addAction(action)
		}
		let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		ac.addAction(cancel)
		
		self.present(ac, animated: true, completion: {})
	}
}

extension AddItemVC: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(actionDone))
		self.navigationItem.setRightBarButton(button, animated: true)
		
		self.currentTextField = textField
	}
	func textFieldDidEndEditing(_ textField: UITextField) {
		guard let text = textField.text else { return }
		guard let identifier = textField.textInputMode?.primaryLanguage else { return }
		
		let nf = NumberFormatter()
		nf.locale = Locale(identifier: identifier)
		if let n = nf.number(from: text) {
			textField.text = "\(n)"
		}
	}
}
