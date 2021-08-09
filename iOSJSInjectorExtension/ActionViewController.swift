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
    var sampleScripts = [JSScriptObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDoneButton()
        addKeyboardObserver()
        addScriptsButton()
        getActionInput()
        loadSampleScripts()
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
    
    func addScriptsButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Scripts", style: .plain, target: self, action: #selector(showSavedScripts))
    }
    
    func addKeyboardObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndframe = keyboardValue.cgRectValue
        let keyboardViewEndframe = view.convert(keyboardScreenEndframe, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndframe.height - view.safeAreaInsets.bottom, right: 0) // Compenstation for safe area on devices with notch
        }
        
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }

    @IBAction func done() {
        let item = NSExtensionItem()
        let arg: NSDictionary = ["customJavaScript": script.text]
        let webDict: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: arg]
        let customJS = NSItemProvider(item: webDict, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJS]
        extensionContext?.completeRequest(returningItems: [item])
    }
    
    @objc func showSavedScripts() {
        let ac = UIAlertController(title: "Saved Scripts", message: "Samples scripts and scripts you save for a site", preferredStyle: .actionSheet)
        
        let savedScripts = UIAlertAction(title: "Saved Scripts", style: .default) { [weak self] _ in
            self?.loadSavedScripts()
        }
        ac.addAction(savedScripts)
        
        for script in getSampleScripts() {
            ac.addAction(script)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        ac.addAction(cancel)
        
        present(ac, animated: true)
    }
    
    func loadSavedScripts() {
        let ac = UIAlertController(title: "Save coming soon", message: "Ability to save and load scripts coming soon", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func getSampleScripts() -> [UIAlertAction] {
        var sampleScriptActions = [UIAlertAction]()
        
        
        if !sampleScripts.isEmpty {
            for script in sampleScripts {
                let scriptAction = UIAlertAction(title: script.title, style: .default) { [weak self] _ in
                    self?.setScript(to: script.script)
                }
                sampleScriptActions.append(scriptAction)
            }
        }

        return sampleScriptActions
    }
    
    func loadSampleScripts() {
        print("Reach 1")
        if let url = Bundle.main.url(forResource: "SampleScripts", withExtension: "json") {
            print("Reach 2")
            if let data = try? Data(contentsOf: url) {
                print("Reach 3")
                let decoder = JSONDecoder()
                if let decodedData = try? decoder.decode([JSScriptObject].self, from: data) {
                    print("Reach 4")
                    sampleScripts += decodedData
                }
            }
        }
    }
    
    func setScript(to value: String) {
        script.text = value
    }

}
