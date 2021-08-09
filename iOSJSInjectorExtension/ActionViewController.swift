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
        addSaveButton()
        addKeyboardObserver()
        addScriptsButton()
        addRunButton()
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
    
    func addSaveButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
    }
    
    func addScriptsButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Scripts", style: .plain, target: self, action: #selector(showSavedScripts))
    }
    
    func addRunButton() {
        let run = UIBarButtonItem(title: "Run", style: .done, target: self, action: #selector(run))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [spacer, run, spacer]
        navigationController?.isToolbarHidden = false
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

    @IBAction func run() {
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
        /*
        let ac = UIAlertController(title: "Save coming soon", message: "Ability to save and load scripts coming soon", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        */
        print(pageURL)
        let vc = SavedScriptsViewController()
        vc.url = pageURL
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
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
    
    @objc func save() {
        let ac = UIAlertController(title: "Save Script?", message: "Please provide a name to save script", preferredStyle: .alert)
        
        ac.addTextField()
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        ac.addAction(cancel)
        
        let save = UIAlertAction(title: "Save", style: .default) { [weak self, weak ac] _ in
            guard let scriptName = ac?.textFields?[0].text else { return }
            guard !scriptName.isEmpty else {
                let warn = UIAlertController(title: "Script name cannot be empty", message: nil, preferredStyle: .alert)
                warn.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(warn, animated: true)
                return
            }
            self?.saveScript(withName: scriptName)
        }
        ac.addAction(save)
        
        present(ac, animated: true)
    }
    
    func saveScript(withName scriptName: String) {
        var savedScripts = [JSScriptObject]()
        
        if let data = UserDefaults.standard.data(forKey: "savedScripts") {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([JSScriptObject].self, from: data) {
                savedScripts += decodedData
            }
        }
        
        let toSave = JSScriptObject(title: scriptName, url: pageURL, script: script.text)
        savedScripts.append(toSave)
        
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(savedScripts) {
            UserDefaults.standard.setValue(jsonData, forKey: "savedScripts")
        }
    }
    
    
    func loadSampleScripts() {
        if let url = Bundle.main.url(forResource: "SampleScripts", withExtension: "json") {
            if let data = try? Data(contentsOf: url) {
                let decoder = JSONDecoder()
                if let decodedData = try? decoder.decode([JSScriptObject].self, from: data) {
                    sampleScripts += decodedData
                }
            }
        }
    }
    
    func setScript(to value: String) {
        script.text = value
    }

}
