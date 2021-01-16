//
//  MaterialTableView.swift
//  ToolNative
//
//  Created by Marcin Kessler on 16.10.20.
//

import UIKit

class MaterialTableView: UITableViewController {
    
    var materials = [Materials]()
    
    var toolID = String()
    
    var defaultURL:URL?
    
    var delegate:MaterialTableViewDelegate?
    
    var editorEnable = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = toolID
        
        self.navigationItem.rightBarButtonItems = [] // Um defaultUrl append
        
        if editorEnable {
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: loadArray(key: SaveKeys.favoriteLibKey.rawValue).contains(toolID) == true ? "star.fill" : "star"), style: .plain, target: self, action: #selector(toggleFavorite))]
        }
        
        if let _ = defaultURL {
            self.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openUrl)))
        }
    }
    
    @objc func openUrl() {
        let vc = BrowserController(url: defaultURL!, delegate: nil)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func toggleFavorite(_ sender:UIBarButtonItem) {
        if sender.image == UIImage(systemName: "star.fill") { // Remove Favorite
            sender.image = UIImage(systemName: "star")
            var favs = Set(loadArray(key: SaveKeys.favoriteLibKey.rawValue))
            favs.remove(toolID)
            saveArray(value: Array(favs), key: SaveKeys.favoriteLibKey.rawValue)
        }else { // Add Favorite
            sender.image = UIImage(systemName: "star.fill")
            var favs = Set(loadArray(key: SaveKeys.favoriteLibKey.rawValue))
            favs.insert(toolID)
            saveArray(value: Array(favs), key: SaveKeys.favoriteLibKey.rawValue)
        }
    }
    
    init(materials: [Materials], toolID:String, defaultURL:URL, delegate:MaterialTableViewDelegate?) {
        self.materials = materials
        self.toolID = toolID
        self.defaultURL = defaultURL
        self.delegate = delegate
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if materials.isEmpty {
            tableView.setEmptyView(message: "Noch kein Material vorhanden")
        }else { tableView.removeEmptyView() }
        
        return materials.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let materialCell = UITableViewCell(style: .default, reuseIdentifier: "materialcell")
        
        materialCell.textLabel?.text = materials[indexPath.row].materialName
        
        return materialCell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        if let cachedImage = loadImageFromDirectory(fileName: materials[indexPath.row].pdfName ?? "") {
            navigationController?.pushViewController(ImageViewer(image: cachedImage, url: materials[indexPath.row].url, materialName: materials[indexPath.row].materialName), animated: true)
        }else {
            let vc = BrowserController(url: materials[indexPath.row].url, delegate: nil, showDone: false)
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        
        if editorEnable {
            return true
        }
        return false
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let alert = UIAlertController(title: NSLocalizedString("Material löschen?", comment: "Material löschen?"),
                                          message: NSLocalizedString("Möchtest du das Material \"\(materials[indexPath.row].materialName)\" löschen?", comment: "Delete Material Description") ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Löschen", comment: "Löschen"), style: .destructive) { (_) in
                
                self.delegate?.deleteMaterial(toolID: self.toolID, material: self.materials[indexPath.row].materialName)
                self.materials.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
            self.present(alert, animated: true, completion: nil)
        }  
    }
    
    
}

protocol MaterialTableViewDelegate {
    func deleteMaterial(toolID:String, material:String)
}
