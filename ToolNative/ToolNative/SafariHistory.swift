//
//  SafariHistory.swift
//  ToolNative
//
//  Created by Marcin Kessler on 20.10.20.
//

import UIKit

class SafariHistory: UITableViewController {
    
    var webHistory = [WebHistory]()
    
    var legende = [
        Legende(imageName: "magnifyingglass", description: "Werkzeugsuche"),
        Legende(imageName: "rectangle.grid.1x2", description: "Werkzeugauswahl"),
        Legende(imageName: "rectangle.grid.2x2", description: "Materialauswahl"),
        Legende(imageName: "a.square", description: "Anwendung auswählen"),
        Legende(imageName: "equal", description: "Schnittdaten"),
        Legende(imageName: "questionmark", description: "Undefiniert"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteHistory(_:)))
        self.navigationItem.rightBarButtonItem?.tintColor = .systemRed
        
        if webHistory.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        title = "Suchverlauf"
        
        print(webHistory)
    }
    
    init(webHistory:[WebHistory]) {
        self.webHistory = webHistory.reversed()
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func deleteHistory(_ sender:UIBarButtonItem) {
        
        let alert = UIAlertController(title: NSLocalizedString("Möchtest du den Verlauf unwiderruflich löschen?", comment: "Möchtest du den Verlauf unwiderruflich löschen?"),
                                      message: NSLocalizedString("Dies kann nicht rückgängig gemacht werden", comment: "Dies kann nicht rückgängig gemacht werden") ,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Löschen", comment: "Löschen"), style: .destructive) { (_) in
            
            sender.isEnabled = false
            saveSafariHistory(value: [], key: SaveKeys.safariHistoryKey.rawValue)
            self.webHistory = []
            self.tableView.reloadData()
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        })
        self.present(alert, animated: true, completion: nil)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if webHistory.isEmpty {
            tableView.setEmptyView(message: "Kein Verlauf vorhanden")
            return 0
        }else { tableView.removeEmptyView() }
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return legende.count }
        return webHistory.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            let legendeCell = UITableViewCell(style: .default, reuseIdentifier: "legendeCell")
            
            legendeCell.imageView?.image = UIImage(systemName: legende[indexPath.row].imageName)
            legendeCell.textLabel?.text = legende[indexPath.row].description
            
            return legendeCell
        }
        
        let webHistoryCell = UITableViewCell(style: .default, reuseIdentifier: "webHistoryCell")
        
        var imageName = "questionmark"
        
        let webHistoryForCell = webHistory[indexPath.row]
        
        switch webHistoryForCell.pageType {
        case .undefined:
            break

        case .toolSearchMask:
            imageName = "magnifyingglass"
        case .toolChoice:
            imageName = "rectangle.grid.1x2"
        case .materialChoice:
            imageName = "rectangle.grid.2x2"
        case .drillLength:
            imageName = "a.square"
        case .finalCutData:
            imageName = "equal"
        }
        
        webHistoryCell.imageView?.image = UIImage(systemName: imageName)
        
        if let toolID = webHistoryForCell.toolID {
            webHistoryCell.textLabel?.text = toolID
        }else if let internalToolID = webHistoryForCell.internalToolID {
            webHistoryCell.textLabel?.text = internalToolID
        }else {
            
            switch webHistoryForCell.url.description {
            case fraisaExpertHomeURL.description:
                webHistoryCell.textLabel?.text = "Fraisa ToolExpert Home"
            case bohrerURL.description :
                webHistoryCell.textLabel?.text = "Bohrer suchen"
            case fräserURL.description :
                webHistoryCell.textLabel?.text = "Fräser suchen"
            default:
                webHistoryCell.textLabel?.text = webHistoryForCell.url.description
            }
           
        }
        
        let accessoryImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        if webHistoryForCell.toolType == .bohrer {
            accessoryImageView.image = UIImage(systemName: "b.square")
            webHistoryCell.accessoryView = accessoryImageView
        }else if webHistoryForCell.toolType == .fräser {
            accessoryImageView.image = UIImage(systemName: "f.square")
            webHistoryCell.accessoryView = accessoryImageView
        }else {
            webHistoryCell.accessoryView = nil
        }
        
        return webHistoryCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section != 0 { return }
        
        let vc = BrowserController(url: webHistory[indexPath.row].url, delegate: self)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Legende" : nil
    }
    
    struct Legende {
        var imageName: String
        var description: String
    }

}

extension SafariHistory :BrowserDelegate {
    func didDismiss() {
        webHistory = loadSafariHistory(key: SaveKeys.safariHistoryKey.rawValue).reversed()
        tableView.reloadData()
    }
    
    
}
