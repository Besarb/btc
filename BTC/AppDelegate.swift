//
//  AppDelegate.swift
//  BTC
//
//  Created by Alex Rivera on 17.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import UIKit
import UserNotifications

#if !DEBUG
	func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		self.setupUI()
	
		let nc = UINavigationController(rootViewController: ViewController())
		
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = nc
		window?.makeKeyAndVisible()
		
		return true
	}
	
	private func setupUI() {
		UINavigationBar.appearance().tintColor = .mainTint
		UINavigationBar.appearance().barTintColor = .navBarBg
		UINavigationBar.appearance().isTranslucent = false
		UINavigationBar.appearance().barStyle = .default
		UINavigationBar.appearance().titleTextAttributes = [
			NSAttributedStringKey.foregroundColor: UIColor.text
		]
		
		UITableViewCell.appearance().backgroundColor = .bg
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		BTCHelper.fetchCurrenciesInfo()
	}
}

