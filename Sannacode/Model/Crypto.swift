//
//  Crypto.swift
//  Sannacode
//
//  Created by Завгородянський Олег on 2/24/18.
//  Copyright © 2018 Завгородянський Олег. All rights reserved.
//

import UIKit

struct Crypto : Decodable {
    let id : String
    let name : String
    let symbol : String
    let rank : String
    let price_usd : String
    let price_btc : String
    let last_updated : String
}
