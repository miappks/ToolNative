//
//  FavoriteHistoryTableView.swift
//  ToolNative
//
//  Created by Marcin Kessler on 17.10.20.
//

import UIKit

class FavoriteHistoryTableView: UITableViewController {

    var allFräser = [Tool]()
    var allBohrer = [Tool]()
    
    var allTools = [[Tool]]()
    
    let tools = loadTools(key: SaveKeys.toolLibKey.rawValue)
    let favorites = loadArray(key: SaveKeys.favoriteLibKey.rawValue)
    
    var history = loadHistory(key: SaveKeys.historyKey.rawValue)
    var webHistory = loadSafariHistory(key: SaveKeys.safariHistoryKey.rawValue)
    
    let switcher = UISegmentedControl()
    
    var toolsIsActive = true
    
    var delegate: HistoryDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        history.reverse()
        
        tools.forEach { (_, tool) in
            if !favorites.contains(tool.toolNumber) { return }
            if tool.toolType == .fräser {
                allFräser.append(tool)
            }else {
                allBohrer.append(tool)
            }
        }
        
        if !allFräser.isEmpty { allTools.append(allFräser.sorted(by: {$0.toolNumber < $1.toolNumber})) }
        if !allBohrer.isEmpty { allTools.append(allBohrer.sorted(by: {$0.toolNumber < $1.toolNumber})) }
        
        tableView.register(UINib(nibName: "ToolCell", bundle: nil), forCellReuseIdentifier: "toolcell")
        
        self.navigationItem.titleView = switcher
        
        switcher.frame = CGRect(x: 0, y: 0, width: 250, height: 40)
        switcher.insertSegment(withTitle: "Favoriten", at: 0, animated: false)
        switcher.insertSegment(withTitle: "Verlauf", at: 1, animated: false)
        switcher.addTarget(self, action: #selector(switchingLib), for: .valueChanged)
        switcher.selectedSegmentIndex = 0
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        webHistory = loadSafariHistory(key: SaveKeys.safariHistoryKey.rawValue)
        history = loadHistory(key: SaveKeys.historyKey.rawValue).reversed()
        tableView.reloadData()
    }
    
    @objc func switchingLib(_ sender: UISegmentedControl) {
        print(sender.selectedSegmentIndex)
        toolsIsActive = sender.selectedSegmentIndex == 0 ? true : false
        tableView.reloadData()
        
        self.navigationItem.rightBarButtonItem = toolsIsActive ? nil : UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteHistory(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = .systemRed
        
        if history.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    @objc func deleteHistory(_ sender:UIBarButtonItem) {
        
        let alert = UIAlertController(title: NSLocalizedString("Möchtest du den Verlauf unwiderruflich löschen?", comment: "Möchtest du den Verlauf unwiderruflich löschen?"),
                                      message: NSLocalizedString("Dies kann nicht rückgängig gemacht werden", comment: "Dies kann nicht rückgängig gemacht werden") ,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Löschen", comment: "Löschen"), style: .destructive) { (_) in
            
            sender.isEnabled = false
            saveHistory(value: [], key: SaveKeys.historyKey.rawValue)
            saveSafariHistory(value: [], key: SaveKeys.safariHistoryKey.rawValue)
            self.history = []
            self.webHistory = []
            self.tableView.reloadData()
        })
        self.present(alert, animated: true, completion: nil)
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if toolsIsActive {
            
            if allTools.isEmpty {
                tableView.setEmptyView(message: "Du hast noch keine Favoriten gespeichert")
            }else { tableView.removeEmptyView() }
            
            return allTools.count
        }
        
        if history.isEmpty {
            tableView.setEmptyView(message: "Kein Verlauf vorhanden")
            return 0
        }else { tableView.removeEmptyView() }
        
        return webHistory.isEmpty ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if toolsIsActive {
            return allTools[section].count
        }
        if section == 0 && !webHistory.isEmpty { return 1 } // History for WebView
        return history.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let toolCell = tableView.dequeueReusableCell(withIdentifier: "toolcell", for: indexPath) as? ToolCell else { return UITableViewCell() }
        let historyCell = UITableViewCell(style: .default, reuseIdentifier: "historyCell")
        
        if toolsIsActive {
            toolCell.toolNumber.text = allTools[indexPath.section][indexPath.row].toolNumber
            toolCell.toolType.text = allTools[indexPath.section][indexPath.row].toolType == .bohrer ? "Bohrer" : "Fräser"
            toolCell.internalToolID.text = allTools[indexPath.section][indexPath.row].internalTooliD
            
            toolCell.accessoryType = .detailDisclosureButton
            
            return toolCell
        }
        
        if indexPath.section == 0 && !webHistory.isEmpty {
            
            historyCell.textLabel?.text = "Web Suchverlauf"
            historyCell.imageView?.image = UIImage(systemName: "safari")
            historyCell.accessoryType = .disclosureIndicator
            
            return historyCell
        }
        
        historyCell.textLabel?.text = history[indexPath.row].value
        historyCell.imageView?.image = history[indexPath.row].inputType == .keyBoard ? UIImage(systemName: "keyboard") : UIImage(systemName: "barcode.viewfinder")
        historyCell.accessoryView = nil
        
        return historyCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if toolsIsActive {
            let vc = MaterialTableView(materials: allTools[indexPath.section][indexPath.row].materials, toolID: allTools[indexPath.section][indexPath.row].toolNumber, defaultURL: allTools[indexPath.section][indexPath.row].defaultUrl, delegate: nil)
            vc.editorEnable = false
            navigationItem.backButtonTitle = "Favoriten"
            navigationController?.pushViewController(vc, animated: true)
            
        }else {
            
            if indexPath.section == 0 && !webHistory.isEmpty {
                navigationController?.pushViewController(SafariHistory(webHistory: webHistory), animated: true)
                return
            }
            self.dismiss(animated: true) { [self] in
                delegate?.openToolWithNumber(toolCode: history[indexPath.row].value, type: history[indexPath.row].inputType)
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        if !toolsIsActive { return }
        
        let vc = BrowserController(url: allTools[indexPath.section][indexPath.row].defaultUrl, delegate: nil)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if toolsIsActive {
            if allTools[section][safe:0]?.toolType == .bohrer {
                return "Bohrer"
            }else if allTools[section][safe:0]?.toolType == .fräser {
                return "Fräser"
            }
            return nil
        }
        
//        if allBarCodeRefs[section][safe:0]?.toolType == nil {
//            return "Unknown"
//        }
//        if allBarCodeRefs[section][safe:0]?.toolType == .bohrer {
//            return "Bohrer"
//        }else if allBarCodeRefs[section][safe:0]?.toolType == .fräser {
//            return "Fräser"
//        }
        
        return nil
    }
    
    init(delegate:HistoryDelegate) {
        self.delegate = delegate
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol HistoryDelegate {
    func openToolWithNumber(toolCode:String, type:historyInputType)
}

struct History: Codable{
    var value:String
    var inputType:historyInputType
}

enum historyInputType:String, Codable {
    case barCode = "barCode"
    case keyBoard = "keyBoard"
}

struct WebHistory: Codable{
    var toolID:String?
    var internalToolID:String?
    var url:URL
    var pageType:webHistoryPageType
    var toolType:webToolType
}

enum webToolType:String, Codable {
    case bohrer = "Bohrer"
    case fräser = "Fraeser"
    case undefined = "undefined"
}

enum webHistoryPageType:String, Codable {
    case toolSearchMask = "searchmask"
    case toolChoice = "toolChoice"
    case materialChoice = "materialChoice"
    case drillLength = "drillLength"
    case finalCutData = "finalCutData"
    case undefined = "undefined"
}

func saveHistory(value:[History],key:String)  {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(value) {
        let defaults = UserDefaults.standard
        defaults.setValue(encoded, forKey: key)
    }
}

func loadHistory(key:String) -> [History] {
    let defaults = UserDefaults.standard
    if let savedPerson = defaults.object(forKey: key) as? Data {
        let decoder = JSONDecoder()
        if let loadedPerson = try? decoder.decode([History].self, from: savedPerson) {
            return loadedPerson
        }
    }
    return []
}

func saveSafariHistory(value:[WebHistory],key:String)  {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(value) {
        let defaults = UserDefaults.standard
        defaults.setValue(encoded, forKey: key)
    }
}

func loadSafariHistory(key:String) -> [WebHistory] {
    let defaults = UserDefaults.standard
    if let savedPerson = defaults.object(forKey: key) as? Data {
        let decoder = JSONDecoder()
        if let loadedPerson = try? decoder.decode([WebHistory].self, from: savedPerson) {
            return loadedPerson
        }
    }
    return []
}
