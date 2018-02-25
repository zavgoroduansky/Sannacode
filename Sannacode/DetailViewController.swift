//
//  DetailViewController.swift
//  Sannacode
//
//  Created by Завгородянський Олег on 2/24/18.
//  Copyright © 2018 Завгородянський Олег. All rights reserved.
//

import UIKit
import Foundation

struct Constants {
    static let maxCryptoFractionDigits = 6
    static let maxUsdFractionDigits = 2
    static let cryptoRegularExpression = "^[0-9]+(?:\\.)?(?:[0-9]{1,6})?$"
    static let usdRegularExpression = "^[0-9]+(?:\\.)?(?:[0-9]{1,2})?$"
    static let maxDigits = 10
}

enum ConvertDirection {
    case fromCryptoToUsd
    case fromUsdToCrupto
}

enum ConvertOperation {
    case multiplication
    case division
}

class DetailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var currencyNameLabel: UILabel!
    @IBOutlet weak var currencyRateLabel: UILabel!
    @IBOutlet weak var cryptoTextField: UITextField!
    @IBOutlet weak var usdTextField: UITextField!
    @IBOutlet weak var actionView: UIView!
    
    private var convertDirection = ConvertDirection.fromCryptoToUsd
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = currencyNameLabel {
                label.text = detail.name
            }
            if let label = currencyRateLabel {
                label.text = "1 \(detail.symbol) = \(detail.price_usd) usd"
            }
        } else {
            if let label = currencyNameLabel {
                label.text = "Crypto not selected"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: Crypto? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    // MARK: - view actions
    
    @IBAction func convertButtonAction(_ sender: UIButton) {
        view.endEditing(true)
        
        switch convertDirection {
        case .fromCryptoToUsd:
            if let currentCrypto = detailItem {
                usdTextField.text = convert(from: cryptoTextField.text!, rate: currentCrypto.price_usd, convertOperation: .multiplication, numberOfDigits: Constants.maxUsdFractionDigits)
            }
        case .fromUsdToCrupto:
            if let currentCrypto = detailItem {
                cryptoTextField.text = convert(from: usdTextField.text!, rate: currentCrypto.price_usd, convertOperation: .division, numberOfDigits: Constants.maxCryptoFractionDigits)
            }
        }
    }

    // MARK: - private methods
    
    func convert(from : String, rate: String, convertOperation : ConvertOperation, numberOfDigits: Int) -> String {
        // need to convert string to double
        var convertedValue = 0.0
        if let doubleFrom = Double(from), let doubleRate = Double(rate) {
            switch convertOperation {
            case .multiplication:
                convertedValue = doubleFrom * doubleRate
            case .division:
                convertedValue = doubleFrom / doubleRate
            }
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = numberOfDigits
        numberFormatter.maximumFractionDigits = numberOfDigits
        
        if var result = numberFormatter.string(from: convertedValue as NSNumber) {
            if result.first == "." {
                result.insert("0", at: result.startIndex)
            }
            return result
        } else {
            return ""
        }
    }
    
    func matches(for regex: String, in text: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.count > 0
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    
    func calculateCOntentOffset(keyboardHeight: CGFloat) -> CGFloat {
        let visibleContentHeight = mainScrollView.contentSize.height - keyboardHeight
        let minContentHeight = actionView.frame.origin.y + actionView.frame.size.height
        if minContentHeight < visibleContentHeight {
            return 0
        }
        return minContentHeight - visibleContentHeight
    }
    
    // MARK: - UITextFieldDelegate methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            convertDirection = .fromCryptoToUsd
        } else if textField.tag == 2 {
            convertDirection = .fromUsdToCrupto
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        
        let currentText = textField.text ?? ""
        var replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if let firstCharacter = replacementText.first {
            // work with dot symbol
            if firstCharacter == "." {
                textField.text = "0"+replacementText
                return false
            }
            
            // work with 0 symbol
            if firstCharacter == "0", replacementText.count > 1 {
                // get second character
                let index = replacementText.index(replacementText.startIndex, offsetBy: 1)
                let secondCharacter = replacementText[index]
                if secondCharacter != "." {
                    replacementText.remove(at: replacementText.startIndex)
                    textField.text = replacementText
                    return false
                }
            }
        }
        
        // max length
        if replacementText.count > Constants.maxDigits {
            return false
        }
        
        // check regular expression
        if textField.tag == 1 {
            return matches(for: Constants.cryptoRegularExpression, in: replacementText)
        } else if textField.tag == 2 {
            return matches(for: Constants.usdRegularExpression, in: replacementText)
        }
        
        return true;
    }
    
    // MARK: - keyboard
    
    @objc func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            mainScrollView.setContentOffset(CGPoint(x: 0, y: calculateCOntentOffset(keyboardHeight: keyboardSize.height)), animated: true)
        }
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            print(keyboardSize)
            mainScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }
    
}

