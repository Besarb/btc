//
//  Request.swift
//  BTC
//
//  Created by Alex Rivera on 18.08.17.
//  Copyright © 2017 Alex Rivera. All rights reserved.
//

import Foundation
import UIKit

class BTCRequest {
	/// API here: https://www.bitstamp.net/api/
	class func fetch(symbol: String, _ completionHandler:@escaping((_ currency: Currency?) -> ())) {
		//NSLog("***** FETCH BTC LAST PRICE: \(symbol.uppercased()) *****")
		
		if UIDevice.isSimulator { completionHandler(nil); return }
		
		let strUrl = "https://www.bitstamp.net/api/v2/ticker/\(symbol)/"
		
		guard let url = URL(string: strUrl) else { completionHandler(nil); return }
		
		let configuration = URLSessionConfiguration.default
		configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
		
		let session = URLSession(configuration: configuration, delegate: BTCRequestDelegate(), delegateQueue: OperationQueue.main)
		
		let task = session.dataTask(with: url) { (optionalData, optionalResponse, optionalError) in
			DispatchQueue.main.async(execute: {
				
				guard let data = optionalData else {
					if let e = optionalError {
						print("ERROR: \(e.localizedDescription)")
						completionHandler(nil)
					} else {
						assertionFailure()
					}
					return
				}
				
				/**/
				
				if let currency = BTCHelper.currency(symbol) {
					currency.json = data.jsonDictionary()
					completionHandler(currency)
				}
				completionHandler(nil)
			})
		}
		
		task.resume()
	}
	
	class func fetchCurrenciesInfo(_ completionHandler:@escaping((_ jsonArray: [[String: Any]]) -> ())) {
		if UIDevice.isSimulator { completionHandler([]); return }
		
		let strUrl = "https://www.bitstamp.net/api/v2/trading-pairs-info/"
		
		guard let url = URL(string: strUrl) else { completionHandler([]); return }

		let configuration = URLSessionConfiguration.default
		configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
		
		let session = URLSession(configuration: configuration, delegate: BTCRequestDelegate(), delegateQueue: OperationQueue.main)
		
		let task = session.dataTask(with: url) { (optionalData, optionalResponse, optionalError) in
			guard let data = optionalData else {
				if let e = optionalError {
					print("ERROR: \(e.localizedDescription)")
					completionHandler([])
				} else {
					assertionFailure()
				}
				return
			}
			
			/**/
			
			let json: [[String: Any]] = data.jsonArray()
			completionHandler(json)
		}
		
		task.resume()
	}
}

class BTCRequestDelegate: NSObject, URLSessionDelegate {
	func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		var secResult = SecTrustResultType.invalid
		
		if SecTrustEvaluate(challenge.protectionSpace.serverTrust!, &secResult) == errSecSuccess {
			completionHandler(.performDefaultHandling, nil)
		} else {
			completionHandler(.cancelAuthenticationChallenge, nil)
		}
	}
}
