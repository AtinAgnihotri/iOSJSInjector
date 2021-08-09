//
//  SavedScriptViewController.swift
//  iOSJSInjectorExtension
//
//  Created by Atin Agnihotri on 09/08/21.
//

import UIKit

class SavedScriptsViewController: UITableViewController {
    
    var url: String!
    var savedScripts = [JSScriptObject]()
    var delegate: ActionViewController!
    
    override func loadView() {
        createTableView()
        title = "Saved Scripts"
    }
    
    func createTableView() {
        view = UIView()
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = 50
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView = table
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadSavedScriptsForURL()
    }

    func loadSavedScriptsForURL() {
        let allScripts = loadSavedScripts()
        for script in allScripts {
            if script.url == url {
                savedScripts.append(script)
            }
        }
        tableView.reloadData()
    }
    
    func loadSavedScripts() -> [JSScriptObject] {
        
        if let data = UserDefaults.standard.data(forKey: "savedScripts") {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([JSScriptObject].self, from: data) {
                return decodedData
            }
        }
        return []
        
        /*
        return [
            JSScriptObject(title: "Apple Title", url: "https://www.apple.com/", script: "alert(document.title);")
        ]
        */
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        savedScripts.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let script = savedScripts[indexPath.row]
        delegate.setScript(to: script.script)
        navigationController?.popViewController(animated: true)
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { fatalError("Failed to dequeue cell") }
        cell.textLabel?.text = savedScripts[indexPath.row].title
        return cell
    }

}
