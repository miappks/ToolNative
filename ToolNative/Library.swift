//
//  Library.swift
//  ToolNative
//
//  Created by Marcin Kessler on 16.10.20.
//

import UIKit
import MBProgressHUD

class Library: UITableViewController {
    
    var allFräser = [Tool]()
    var allBohrer = [Tool]()
    
    var allFräserBarcodeRefs = [BarCodeRef]()
    var allBohrerBarcodeRefs = [BarCodeRef]()
    var allUnknownBarcodeRefs = [BarCodeRef]()
    
    var allTools = [[Tool]]()
    var allBarCodeRefs = [[BarCodeRef]]()
    
    let tools = loadTools(key: SaveKeys.toolLibKey.rawValue)
    var barCodeReference = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
    
    let switcher = UISegmentedControl()
    
    var toolsIsActive = true
    
    var delegate: BrowserDelegate?
    
    var indexForBarCode = IndexPath()
    var lastSelectedIndex:IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tools.forEach { (_, tool) in
            if tool.toolType == .fräser {
                allFräser.append(tool)
            }else {
                allBohrer.append(tool)
            }
        }
        
        if !allFräser.isEmpty { allTools.append(allFräser.sorted(by: {$0.toolNumber < $1.toolNumber})) }
        if !allBohrer.isEmpty { allTools.append(allBohrer.sorted(by: {$0.toolNumber < $1.toolNumber})) }
        
        setupBarCodeReference()
        
        tableView.register(UINib(nibName: "ToolCell", bundle: nil), forCellReuseIdentifier: "toolcell")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        
        self.navigationItem.titleView = switcher
        
        switcher.frame = CGRect(x: 0, y: 0, width: 250, height: 40)
        switcher.insertSegment(withTitle: "Werkzeuge", at: 0, animated: false)
        switcher.insertSegment(withTitle: "Barcode ID's", at: 1, animated: false)
        switcher.addTarget(self, action: #selector(switchingLib), for: .valueChanged)
        switcher.selectedSegmentIndex = 0
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = lastSelectedIndex {
            tableView.reloadRows(at: [indexPath], with: .fade)
            lastSelectedIndex = nil
        }
    }
    
    func setupBarCodeReference() {
        
        let t = loadTools(key: SaveKeys.toolLibKey.rawValue)
        
        barCodeReference = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
        
        allFräserBarcodeRefs = [BarCodeRef]()
        allBohrerBarcodeRefs = [BarCodeRef]()
        allUnknownBarcodeRefs = [BarCodeRef]()
        
        allBarCodeRefs = [[BarCodeRef]]()
        
        barCodeReference.forEach { (barCodeID, toolNumber) in
            if let toolValue = t[toolNumber] {
                if toolValue.toolType == .bohrer {
                    allBohrerBarcodeRefs.append(BarCodeRef(barCodeNumber: barCodeID, toolNumber: toolNumber, toolType: toolValue.toolType))
                }else if toolValue.toolType == .fräser {
                    allFräserBarcodeRefs.append(BarCodeRef(barCodeNumber: barCodeID, toolNumber: toolNumber, toolType: toolValue.toolType))
                }
            }else {
                allUnknownBarcodeRefs.append(BarCodeRef(barCodeNumber: barCodeID, toolNumber: toolNumber, toolType: nil))
            }
        }
        
        if !allFräserBarcodeRefs.isEmpty { allBarCodeRefs.append(allFräserBarcodeRefs.sorted(by: {$0.toolNumber < $1.toolNumber})) }
        if !allBohrerBarcodeRefs.isEmpty { allBarCodeRefs.append(allBohrerBarcodeRefs.sorted(by: {$0.toolNumber < $1.toolNumber})) }
        if !allUnknownBarcodeRefs.isEmpty { allBarCodeRefs.append(allUnknownBarcodeRefs.sorted(by: {$0.toolNumber < $1.toolNumber})) }
    }
    
    @objc func switchingLib(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 { setupBarCodeReference() }
        print(sender.selectedSegmentIndex)
        toolsIsActive = sender.selectedSegmentIndex == 0 ? true : false
        tableView.reloadData()
        self.navigationItem.leftBarButtonItem = toolsIsActive ? UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings)) : UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addBarCodeReference))
    }
    
    @objc func openSettings() {
        let drillScheme = loadString(key: "drillScheme", defaultValue: "B62015")
        
        let ac = UIAlertController(title: "Fast Drill Search", message: """
                Bohrerschema ändern

                Aktuell: \(drillScheme)####
                """, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].text = drillScheme
        ac.textFields![0].autocapitalizationType = .allCharacters
        
        ac.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        
        let submitAction = UIAlertAction(title: "Speichern", style: .default) { [self, unowned ac] _ in
            if let bohrerschema = ac.textFields![0].text {
                if bohrerschema.trimmingCharacters(in: .whitespaces) != "" {
                    saveString(value: bohrerschema.trimmingCharacters(in: .whitespaces), key: "drillScheme")
                    DoneHUD.showInView(self.view, message: "Gespeichert")
                }
            }
            
        }
        
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    @objc func addBarCodeReference() {
        let ac = UIAlertController(title: "Werkzeugbezeichnung / Bestellnummer eingeben", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].autocapitalizationType = .allCharacters
        
        ac.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        
        let submitAction = UIAlertAction(title: "Barcode scannen", style: .default) { [self, unowned ac] _ in
            if let bez = ac.textFields![0].text?.trimmingCharacters(in: .whitespaces) {
                if bez == "" { showAlert(title: "Ungültige Bestellnummer", message: nil); return }
                let vc = ScannerViewController()
                vc.delegate = self
                vc.tag = bez
                vc.tag2 = 1
                self.present(vc, animated: true, completion: nil)
            }
            
        }
        
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if toolsIsActive {
            
            if allTools.isEmpty {
                tableView.setEmptyView(message: "Es befinden sich noch keine Werkzeuge in der Bibliothek")
            }else { tableView.removeEmptyView() }
            
            return allTools.count
        }
        
        if allBarCodeRefs.isEmpty {
            tableView.setEmptyView(message: "Du hast noch keine Barcodes hinzugefügt")
        }else { tableView.removeEmptyView() }
        
        return allBarCodeRefs.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if toolsIsActive {
            return allTools[section].count
        }
        
        return allBarCodeRefs[section].count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let toolCell = tableView.dequeueReusableCell(withIdentifier: "toolcell", for: indexPath) as? ToolCell else { return UITableViewCell() }
        let barCodeCell = UITableViewCell(style: .value1, reuseIdentifier: "barCodeCell")
        
        if toolsIsActive {
            toolCell.toolNumber.text = allTools[indexPath.section][indexPath.row].toolNumber
            toolCell.toolType.text = allTools[indexPath.section][indexPath.row].toolType == .bohrer ? "Bohrer" : "Fräser"
            toolCell.internalToolID.text = allTools[indexPath.section][indexPath.row].internalTooliD
            
            let hasMaterial = !allTools[indexPath.section][indexPath.row].materials.isEmpty
            
            if let _ = barCodeReference.someKey(forValue: allTools[indexPath.section][indexPath.row].toolNumber) {
                if hasMaterial {
                    toolCell.accessoryType = .disclosureIndicator
                }else {
                    toolCell.accessoryType = .none
                }
                
            }else {
                if hasMaterial {
                    toolCell.accessoryType = .detailDisclosureButton
                }else {
                    toolCell.accessoryType = .detailButton
                }
            }
            
            if loadArray(key: SaveKeys.favoriteLibKey.rawValue).contains(allTools[indexPath.section][indexPath.row].toolNumber) {
                toolCell.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.5)
                let selectedBackgroundView = UIView()
                selectedBackgroundView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.6)
                toolCell.selectedBackgroundView = selectedBackgroundView
            }else {
                toolCell.backgroundColor = nil
                toolCell.selectedBackgroundView = nil
            }
            
            
            return toolCell
        }
        
        barCodeCell.textLabel?.text = allBarCodeRefs[indexPath.section][indexPath.row].barCodeNumber
        barCodeCell.detailTextLabel?.text = allBarCodeRefs[indexPath.section][indexPath.row].toolNumber
        
        return barCodeCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if toolsIsActive {
            if allTools[indexPath.section][indexPath.row].materials.isEmpty {
                let browserVC = BrowserController(url: allTools[indexPath.section][indexPath.row].defaultUrl, delegate: self, showDone: false)
                navigationController?.pushViewController(browserVC, animated: true)
                return
            }
            
            navigationController?.pushViewController(MaterialTableView(materials: allTools[indexPath.section][indexPath.row].materials, toolID: allTools[indexPath.section][indexPath.row].toolNumber, defaultURL: allTools[indexPath.section][indexPath.row].defaultUrl, delegate: self), animated: true)
            navigationItem.backButtonTitle = "Tools"
            lastSelectedIndex = indexPath
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        if !toolsIsActive { return }
        
        let alert = UIAlertController(title: "Barcode hinzufügen?",
                                      message: "Möchtest du einen Barcode für das Werkzeug hinzufügen?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Hinzufügen", style: .default, handler: { [self] (action) in
            let vc = ScannerViewController()
            vc.delegate = self
            vc.tag = allTools[indexPath.section][indexPath.row].toolNumber
            indexForBarCode = indexPath
            self.present(vc, animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            if !toolsIsActive {
                
                let barCodeNummer = allBarCodeRefs[indexPath.section][indexPath.row].barCodeNumber
                allBarCodeRefs[indexPath.section].remove(at: indexPath.row)
                var newRef = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
                newRef.removeValue(forKey: barCodeNummer)
                saveDict(value: newRef, key: SaveKeys.barCodeLibKey.rawValue)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                return
            }
            
            let alert = UIAlertController(title: NSLocalizedString("Werkzeug wirklich löschen?", comment: "Werkzeug wirklich löschen?"),
                                          message: NSLocalizedString("Möchtest du das Werkzeug \"\(self.allTools[indexPath.section][indexPath.row].toolNumber)\" aus der Bibliothek löschen?", comment: "Delete Tool Description") ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Löschen", comment: "Löschen"), style: .destructive) { (_) in
                
                self.deleteTool(toolID: self.allTools[indexPath.section][indexPath.row].toolNumber)
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
            self.present(alert, animated: true, completion: nil)
            
        }
    }
 */
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let TrashAction = UIContextualAction(style: .destructive, title:  "Löschen", handler: { (ac:UIContextualAction, view:UIView, completion:(Bool) -> Void) in
            if !self.toolsIsActive {
                
                let barCodeNummer = self.allBarCodeRefs[indexPath.section][indexPath.row].barCodeNumber
                self.allBarCodeRefs[indexPath.section].remove(at: indexPath.row)
                var newRef = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
                newRef.removeValue(forKey: barCodeNummer)
                saveDict(value: newRef, key: SaveKeys.barCodeLibKey.rawValue)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                return
            }
            
            let alert = UIAlertController(title: NSLocalizedString("Werkzeug wirklich löschen?", comment: "Werkzeug wirklich löschen?"),
                                          message: NSLocalizedString("Möchtest du das Werkzeug \"\(self.allTools[indexPath.section][indexPath.row].toolNumber)\" aus der Bibliothek löschen?", comment: "Delete Tool Description") ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Löschen", comment: "Löschen"), style: .destructive) { (_) in
                
                self.deleteTool(toolID: self.allTools[indexPath.section][indexPath.row].toolNumber)
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
            self.present(alert, animated: true, completion: nil)
            completion(true)
        })
        
        let addToFavorit = UIContextualAction(style: .normal, title:  "Zu Favoriten hinzufügen", handler: { (ac:UIContextualAction, view:UIView, completion:(Bool) -> Void) in
            var favs = Set(loadArray(key: SaveKeys.favoriteLibKey.rawValue))
            favs.insert(self.allTools[indexPath.section][indexPath.row].toolNumber)
            saveArray(value: Array(favs), key: SaveKeys.favoriteLibKey.rawValue)
            
            tableView.reloadRows(at: [indexPath], with: .fade)
        })
        
        let removeFromFavorit = UIContextualAction(style: .normal, title:  "Favorit entfernen", handler: { (ac:UIContextualAction, view:UIView, completion:(Bool) -> Void) in
            
            var favs = Set(loadArray(key: SaveKeys.favoriteLibKey.rawValue))
            favs.remove(self.allTools[indexPath.section][indexPath.row].toolNumber)
            saveArray(value: Array(favs), key: SaveKeys.favoriteLibKey.rawValue)
            tableView.reloadRows(at: [indexPath], with: .fade)
        })
        
        addToFavorit.image = UIImage(systemName: "star.fill")
        addToFavorit.backgroundColor = .systemOrange
        removeFromFavorit.image = UIImage(systemName: "star.slash.fill")
        removeFromFavorit.backgroundColor = .systemGray
        
        if toolsIsActive {
            TrashAction.image = UIImage(systemName: "trash")
            if loadArray(key: SaveKeys.favoriteLibKey.rawValue).contains(allTools[indexPath.section][indexPath.row].toolNumber) {
                return UISwipeActionsConfiguration(actions: [TrashAction, removeFromFavorit])
            }else {
                return UISwipeActionsConfiguration(actions: [TrashAction, addToFavorit])
            }
            
        }else {
            return UISwipeActionsConfiguration(actions: [TrashAction])
        }
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
        
        if allBarCodeRefs[section][safe:0]?.toolType == nil {
            return "Unknown"
        }
        if allBarCodeRefs[section][safe:0]?.toolType == .bohrer {
            return "Bohrer"
        }else if allBarCodeRefs[section][safe:0]?.toolType == .fräser {
            return "Fräser"
        }
        
        return nil
    }
    
    func deleteTool(toolID: String) {
        
        for (toolTypeIndex, toolClass) in allTools.enumerated() {
            for (i, tool) in toolClass.enumerated() {
                if tool.toolNumber == toolID {
                    allTools[toolTypeIndex].remove(at: i)
                    var newLib = loadTools(key: SaveKeys.toolLibKey.rawValue)
                    newLib.removeValue(forKey: toolID)
                    saveTools(value: newLib, key: SaveKeys.toolLibKey.rawValue)
                    
                    tool.materials.forEach { (material) in
                        if let pdfName = material.pdfName {
                            deleteFileFromDirectory(imageName: pdfName)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        delegate?.didDismiss()
    }
    
    init(delegate:BrowserDelegate?) {
        self.delegate = delegate
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func share() {
        
        let alert = UIAlertController(title: "Werkzeugbibliothek teilen",
                                      message: "Was möchtest du teilen?" ,
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Werkzeugbibliothek", style: .default) { [self] (_) in
            
            let allTools = loadTools(key: SaveKeys.toolLibKey.rawValue)
            
            let alert = UIAlertController(title: "Daten komprimieren",
                                          message: "Wenn du die Daten komprimierst, kannst du bis zu 50% Speicherplatz einsparen. Die Qualität der Schnittdatenbilder nimmt aber ab" ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Komprimieren", style: .default) { (_) in
                
                let toolLibrary = ExportLibraryData(toolLibrary: allTools, barCodes: [:], imageData: getAllImages(allTools: allTools, compress: true), exportType: .toolLibrary)
                self.presentActivitySheet(data: toolLibrary)
                
            })
            
            alert.addAction(UIAlertAction(title: "Nicht komprimieren", style: .default) { (_) in
                
                let toolLibrary = ExportLibraryData(toolLibrary: allTools, barCodes: [:], imageData: getAllImages(allTools: allTools, compress: false), exportType: .toolLibrary)
                self.presentActivitySheet(data: toolLibrary)
                
            })
            self.present(alert, animated: true, completion: nil)
            
        })
        
        alert.addAction(UIAlertAction(title: "Barcodebibliothek", style: .default) { (_) in
            
            let barcodeLibrary = ExportLibraryData(toolLibrary: [:], barCodes: loadDict(key: SaveKeys.barCodeLibKey.rawValue), imageData: [:], exportType: .barcodeLibrary)
            self.presentActivitySheet(data: barcodeLibrary)
            
        })
        
        alert.addAction(UIAlertAction(title: "Werkzeug & Barcode Bibliothek", style: .default) { (_) in
            
            let allTools = loadTools(key: SaveKeys.toolLibKey.rawValue)
            
            let alert = UIAlertController(title: "Daten komprimieren",
                                          message: "Wenn du die Daten komprimierst, kannst du bis zu 50% Speicherplatz einsparen. Die Qualität der Schnittdatenbilder nimmt aber ab" ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Komprimieren", style: .default) { (_) in
                
                let exportedLibrary = ExportLibraryData(toolLibrary: allTools, barCodes: loadDict(key: SaveKeys.barCodeLibKey.rawValue), imageData: self.getAllImages(allTools: allTools, compress: true), exportType: .barcodeAndToolLibrary)
                self.presentActivitySheet(data: exportedLibrary)
                
            })
            
            alert.addAction(UIAlertAction(title: "Nicht komprimieren", style: .default) { (_) in
                
                let exportedLibrary = ExportLibraryData(toolLibrary: allTools, barCodes: loadDict(key: SaveKeys.barCodeLibKey.rawValue), imageData: self.getAllImages(allTools: allTools, compress: false), exportType: .barcodeAndToolLibrary)
                self.presentActivitySheet(data: exportedLibrary)
                
            })
            self.present(alert, animated: true, completion: nil)
            
        })
        
        alert.addAction(UIAlertAction(title: "Export für Tool for Win", style: .default, handler: { (_) in
            
            let allTools = loadTools(key: SaveKeys.toolLibKey.rawValue)
            
            var exportString = String()
            
            allTools.forEach { (_,tool) in
                exportString += "\(tool.toolNumber)=\(tool.internalTooliD);"
            }
            exportString.removeLast()
            
            let shareSheet = UIActivityViewController(activityItems: [exportString], applicationActivities: nil)
            self.present(shareSheet, animated: true, completion: nil)
            
        }))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func getAllImages(allTools: [String : Tool], compress:Bool) -> [String : SchnittdatenImage]{
        var imageData = [String:SchnittdatenImage]()
        
        allTools.forEach { (_, tool) in
            tool.materials.forEach { (material) in
                if let imageName = material.pdfName {
                    if let cachedImage = loadImageFromDirectory(fileName: imageName) {
                        
                        if compress {
                            if let reducedImage = cachedImage.jpegData(compressionQuality: 0.5) {
                                imageData[imageName] = SchnittdatenImage(photo: UIImage(data: reducedImage) ?? cachedImage)
                            }else {
                                imageData[imageName] = SchnittdatenImage(photo: cachedImage)
                            }
                        }else {
                            imageData[imageName] = SchnittdatenImage(photo: cachedImage)
                        }
                        
                        
                    }
                }
                
            }
        }
        
        return imageData
    }
    
    func presentActivitySheet(data:ExportLibraryData) {
        
        guard let url = exportToFileURL(exportFile: data) else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}

extension Library: MaterialTableViewDelegate {
    func deleteMaterial(toolID: String, material:String) {
        
        for (toolTypeIndex, toolClass) in allTools.enumerated() {
            for (i, tool) in toolClass.enumerated() {
                if tool.toolNumber == toolID {
                    for (materialIndex, materialName) in allTools[toolTypeIndex][i].materials.enumerated() {
                        if materialName.materialName == material {
                            if let pdfName = allTools[toolTypeIndex][i].materials[materialIndex].pdfName {
                                deleteFileFromDirectory(imageName: pdfName)
                            }
                            allTools[toolTypeIndex][i].materials.remove(at: materialIndex)
                            
                            var newToolLib = loadTools(key: SaveKeys.toolLibKey.rawValue)
                            guard let toolFromNewLib = newToolLib[toolID] else { return }
                            for (newLibI, materials) in toolFromNewLib.materials.enumerated() {
                                if materials.materialName == material {
                                    newToolLib[toolID]?.materials.remove(at: newLibI)
                                    saveTools(value: newToolLib, key: SaveKeys.toolLibKey.rawValue)
                                }
                            }
                        }
                        
                    }
                }
            }
        }
    }
}

extension Library: ScannerDelegate {
    func foundContent(string: String, tag: String, tag2:Int) {
        if tag != "" { // Save Tool
            barCodeReference[string] = tag
            saveDict(value: barCodeReference, key: SaveKeys.barCodeLibKey.rawValue)
            DoneHUD.showInView(self.view, message: "Barcode hinzugefügt")
            barCodeReference.forEach { (barCodeID, toolNumber) in
                if let toolValue = loadTools(key: SaveKeys.toolLibKey.rawValue)[toolNumber] {
                    allBarCodeRefs[allBarCodeRefs.count - 1].append(BarCodeRef(barCodeNumber: string, toolNumber: tag, toolType: toolValue.toolType))
                    setupBarCodeReference()
                    if tag2 == 1 { // Adding new BarCodeKey on Barcodereference
                        tableView.reloadData()
                    }else {
                        tableView.reloadRows(at: [indexForBarCode], with: .fade)
                    }
                    
                }else {
                    if allBarCodeRefs.isEmpty {
                        allBarCodeRefs.append([BarCodeRef(barCodeNumber: string, toolNumber: tag, toolType: nil)])
                    }else {
                        allBarCodeRefs[allBarCodeRefs.count - 1].append(BarCodeRef(barCodeNumber: string, toolNumber: tag, toolType: nil))
                    }
                    
                    setupBarCodeReference()
                    if tag2 == 1 { // Adding new BarCodeKey on Barcodereference
                        tableView.reloadData()
                    }else {
                        tableView.reloadRows(at: [indexForBarCode], with: .fade)
                    }
                }
            }
            
        }
    }
    
    
}

extension Library:BrowserDelegate {
    func didDismiss() {
        
    }
    
    
}

struct BarCodeRef {
    var barCodeNumber:String
    var toolNumber:String
    var toolType:ToolType?
}
