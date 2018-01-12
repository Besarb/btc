//
//  Request.swift
//  SQChartsFramework
//
//  Created by Alex Rivera on 12.09.17.
//  Copyright © 2017 Swissquote. All rights reserved.
//

import Foundation

public class SQCRequest {
	public class func fetchData(_ session: URLSession, strUrl: String, _ completionHandler: @escaping (Bool, Foundation.Data) -> ()) {
		print("🔅", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", strUrl)
		
		guard let url = URL(string: strUrl) else {
			print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "MALFORMED URL \(strUrl)")
			completionHandler(false, Data())
			return
		}

		let task = session.dataTask(with: url, completionHandler: { (optionalData, optionalResponse, optionalError) -> Void in
			
			guard let data = optionalData else {
				if let error = optionalError {
					print("‼️", "<\(#file.components(separatedBy: "/").last ?? "") (\(#line)) - \(#function)>", "ERROR", error.localizedDescription)
				}
				completionHandler(false, Data())
				return
			}
			
			completionHandler(true, data)
		})
		
		task.resume()
	}
}

public class SQCRequestSessionDelegate: NSObject, URLSessionTaskDelegate {
	public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

		//Accept self-signed certificates
		//completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))

		if challenge.previousFailureCount > 0 {
			completionHandler(.rejectProtectionSpace, nil)
			return
		} else {
			if let credential = challenge.proposedCredential {
				completionHandler(.useCredential,credential)
				return
			}
		}

		completionHandler(.performDefaultHandling, nil)
	}

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		print("------------------------------------------------")
		print("---session", session)
		print("---task", task)
		print("---error", String(describing: error))
	}
}

