//
//  ActionViewController.swift
//  iOSJSInjectorExtension
//
//  Created by Atin Agnihotri on 09/08/21.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {


    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDoneButton()
        getActionInput()
    }
    
    func getActionInput() {
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let jsValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    self?.pageTitle = jsValues["title"] as? String ?? ""
                    self?.pageURL = jsValues["URL"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
    }
    
    func addDoneButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    @IBAction func done() {
        let item = NSExtensionItem()
        let arg: NSDictionary = ["customJavaScript": script.text]
        let webDict: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: arg]
        let customJS = NSItemProvider(item: webDict, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJS]
        extensionContext?.completeRequest(returningItems: [item])
    }

}
