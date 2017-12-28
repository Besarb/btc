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
	class func fetch(symbol: String, _ completionHandler:@escaping((_ success: Bool) -> ())) {
		//NSLog("***** FETCH BTC LAST PRICE: \(symbol.uppercased()) *****")
		
		if UIDevice.isSimulator { completionHandler(true); return }
		
		let strUrl = "https://www.bitstamp.net/api/v2/ticker/\(symbol)/"
		
		guard let url = URL(string: strUrl) else { completionHandler(false); return }
		
		let configuration = URLSessionConfiguration.default
		configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
		
		let session = URLSession(configuration: configuration, delegate: BTCRequestDelegate(), delegateQueue: OperationQueue.main)
		
		let task = session.dataTask(with: url) { (optionalData, optionalResponse, optionalError) in
			DispatchQueue.main.async(execute: {
				
				guard let data = optionalData else {
					if let e = optionalError {
						print("ERROR: \(e.localizedDescription)")
						completionHandler(false)
					} else {
						assertionFailure()
					}
					return
				}
				
				/**/
				
				if let currency = BTCHelper.currency(symbol) {
					currency.json = data.jsonDictionary()
				}
				completionHandler(true)
			})
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
