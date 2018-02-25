//
//  SCRemoteManager.swift
//  Sannacode
//
//  Created by Завгородянський Олег on 2/24/18.
//  Copyright © 2018 Завгородянський Олег. All rights reserved.
//

import UIKit
import Alamofire

class RemoteManager {
    
    static let baseURL = "https://api.coinmarketcap.com/v1/ticker/"
    
    func fetchCrypto(from: Int, limit: Int, completion: @escaping ([Crypto], String) -> Void) {
        let utilityQueue = DispatchQueue.global(qos: .utility)
        let url = RemoteManager.baseURL+"?start=\(from)&limit=\(limit)"
        
        Alamofire.request(url).responseJSON(queue: utilityQueue) { response in
            DispatchQueue.main.async {
                guard response.result.isSuccess else {
                    if let description = response.result.error?.localizedDescription {
                        completion([], "Error while fetching crypto: \(description)")
                    }
                    return
                }
                if let data = response.data {
                    do {
                        let cryptoArray = try JSONDecoder().decode([Crypto].self, from: data)
                        completion(cryptoArray, "")
                    } catch {
                        completion([], "Error while fetching crypto: data format was changed")
                    }
                }
            }
        }
    }
}
