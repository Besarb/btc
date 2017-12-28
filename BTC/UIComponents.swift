//
//  UIComponents.swift
//  BTC
//
//  Created by Alex Rivera on 18.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import Foundation
import UIKit

public class UIComponents {
	public class func view(parent: UIView? = nil, bgColor: UIColor = .bg) -> UIView {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = bgColor
		
		if parent != nil {
			parent!.addSubview(view)
		}
		
		return view
	}
	
	public class func textField(parent: UIView? = nil, placeHolder: String? = nil, keyboardType: UIKeyboardType = .numberPad, textAlignment: NSTextAlignment = .right, fontSize: CGFloat = 15.0, borderStyle: UITextBorderStyle = .roundedRect) -> UITextField {
		let textField = UITextField()
		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.backgroundColor = .textSecondary
		textField.textColor = .text
		textField.borderStyle = borderStyle
		textField.autocapitalizationType = .none
		textField.autocorrectionType = .no
		textField.adjustsFontSizeToFitWidth = true
		textField.minimumFontSize = 11.0;
		textField.clearButtonMode = .whileEditing
		textField.clearsOnBeginEditing = false
		textField.returnKeyType = .done
		textField.tintColor = textField.textColor;
		
		textField.keyboardType = keyboardType
		textField.textAlignment = textAlignment
		textField.font = UIFont.systemFont(ofSize: fontSize)
		
		if placeHolder != nil {
			textField.placeholder = placeHolder
		}
		
		if parent != nil {
			parent!.addSubview(textField)
		}
		
		return textField
	}
	
	public class func chevron(parent: UIView?, bgColor: UIColor = .bg) -> UILabel {
		return self.label(parent: parent, bgColor: bgColor, text: "❯", textColor: .lightGray, fontSize: 18.0)
	}
	
	public class func label(parent: UIView? = nil, bgColor: UIColor = .bg, text: String = "", textColor: UIColor = .text, fontSize: CGFloat = 15.0, textAlignment: NSTextAlignment = .left) -> UILabel {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.backgroundColor = bgColor
		label.font = UIFont.systemFont(ofSize: fontSize)
		label.adjustsFontSizeToFitWidth = true
		label.minimumScaleFactor = 0.6
		label.text = text
		label.textColor = textColor
		label.textAlignment = textAlignment
		
		if parent != nil {
			parent!.addSubview(label)
		}
		
		return label
	}
	
	public class func buttonUnboxed(parent: UIView? = nil, title: String = "", titleColor: UIColor = .blue, fontSize: CGFloat = 15.0) -> UIButton {
		let button = UIButton(type: .custom)
		button.translatesAutoresizingMaskIntoConstraints = false
		button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
		button.titleLabel?.adjustsFontSizeToFitWidth = true
		button.titleLabel?.minimumScaleFactor = 0.6
		if !title.isEmpty {
			button.setTitle(title, for: .normal)
		}
		button.setTitleColor(titleColor, for: .normal)
		button.setTitleColor(.gray, for: .disabled)
		
		if parent != nil {
			parent!.addSubview(button)
		}
		
		return button
	}
	
	public class func buttonBoxed(parent: UIView? = nil, title: String = "", titleColor: UIColor = .white, bgColor: UIColor = .blue, fontSize: CGFloat = 15.0) -> UIButton {
		let button = self.buttonUnboxed(parent: parent, title: title, titleColor: titleColor, fontSize: fontSize)
		button.layer.cornerRadius = 4.0
		button.backgroundColor = bgColor
		button.tintColor = bgColor
		return button
	}
	
	public class func switchView(parent: UIView? = nil, tintColor: UIColor = .blue) -> UISwitch {
		let sw = UISwitch()
		sw.translatesAutoresizingMaskIntoConstraints = false
		sw.tintColor = tintColor
		sw.onTintColor = tintColor
		
		if parent != nil {
			parent!.addSubview(sw)
		}
		
		return sw
	}
}
