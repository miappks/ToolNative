//
//  ViewController.swift
//  ToolNative
//
//  Created by Marcin Kessler on 15.10.20.
//

import UIKit
import SafariServices

enum SaveKeys : String {
    case toolLibKey = "toolLibrary"
    case barCodeLibKey = "referenceLibrary"
    case favoriteLibKey = "favoriteLibrary"
    case historyKey = "historyKey"
    case safariHistoryKey = "safariHistoryKey"
}

let fraisaExpertHomeURL = URL(string: "https://www.fraisa.com/toolexpert/2.0.21/#!/de/start")!
let fräserURL = URL(string: "https://www.fraisa.com/toolexpert/2.0.21/#!/de/mode/search/tooltype/F/norm/normid/tab/zk/usecase/articleNo/d1/d2/d3/l1/l2/l3/z/r/b/H/L/deg45/CutMat/ShaftType/ToolType/performance_class/coating//beta/worktype/group/toolid/json/append/search")!

let bohrerURL = URL(string: "https://www.fraisa.com/toolexpert/2.0.21/#!/de/mode/search/tooltype/B/norm/normid/tab/zk/usecase/articleNo/d1/d2/d3/l1/l2/l3/z/r/b/H/L/deg45/CutMat/ShaftType/ToolType/performance_class/coating//beta/worktype/group/toolid/json/append/search")!

class ToolNative: UIViewController {
    
    @IBOutlet weak var codeInput: UIButton!
    @IBOutlet weak var codeReader: UIButton!
    
    @IBOutlet weak var toolExpert: UIButton!
    @IBOutlet weak var fräser: UIButton!
    @IBOutlet weak var bohrer: UIButton!
    @IBOutlet weak var library: UIButton!
    @IBOutlet weak var cachedSchnittDatenView: UIView!
    @IBOutlet weak var cachedImage: UIImageView!
    @IBOutlet weak var darkBackgroundView: UIView!
    @IBOutlet weak var cacheFinish: UIButton!
    @IBOutlet weak var cacheWeb: UIButton!
    @IBOutlet weak var cachedMaterialName: UILabel!
    @IBOutlet weak var fastDrillSearch: UIButton!
    @IBOutlet weak var favoriten: UIButton!
    
    var cachedOnlineURL: URL?
    
    var werkzeuge = [String:Tool]()
    var barCodeReferences = [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        werkzeuge = loadTools(key: SaveKeys.toolLibKey.rawValue)
        barCodeReferences = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didDismiss), name: NSNotification.Name("reloadData"), object: nil)
        
        
        let favoritenLongTap = UILongPressGestureRecognizer(target: self, action: #selector(quickOpenVerlauf))
        favoriten.addGestureRecognizer(favoritenLongTap)
    }
    
    @objc func quickOpenVerlauf() {
        let vc = SafariHistory(webHistory: loadSafariHistory(key: SaveKeys.safariHistoryKey.rawValue))
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @IBAction func openCodeInput(_ sender: UIButton) {
        let ac = UIAlertController(title: "Werkzeugbezeichnung / Bestellnummer eingeben", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].autocapitalizationType = .allCharacters
        ac.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        
        let submitAction = UIAlertAction(title: "Suchen", style: .default) { [self, unowned ac] _ in
            if let bez = ac.textFields![0].text?.trimmingCharacters(in: .whitespaces) {
                if bez == "" { return }
                openWerkzeuge(bestellNummer: bez)
                
                addToHistory(history: History(value: bez, inputType: .keyBoard))
            }
            
        }
        
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: UIButton) {
        let libVC = Library(delegate: self)
        self.present(UINavigationController(rootViewController: libVC), animated: true, completion: nil)
    }
    
    @IBAction func openFavorites(_ sender: UIButton) {
        let vc = FavoriteHistoryTableView(delegate: self)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @IBAction func openBarCodeReader(_ sender: UIButton) {
        let vc = ScannerViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func openToolExpert(_ sender: UIButton) {
        //self.performSegue(withIdentifier: "browse", sender: self)
        openTab(url: fraisaExpertHomeURL)
    }
    
    @IBAction func openToolExpertFraeser(_ sender: UIButton) {
        openTab(url: fräserURL)
    }
    
    @IBAction func openToolExpertBohrer(_ sender: UIButton) {
        openTab(url: bohrerURL)
    }
    
    @IBAction func fastDrillSearch(_ sender: UIButton) {
        
        let drillScheme = loadString(key: "drillScheme", defaultValue: "B62015")
        
        let ac = UIAlertController(title: "Bohrerdurchmesser eingeben", message: "Schema: \(drillScheme)####", preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].keyboardType = .decimalPad
        
        ac.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        
        let submitAction = UIAlertAction(title: "Suchen", style: .default) { [self, unowned ac] _ in
            if let durchmesser = Double(ac.textFields![0].text ?? "") {
                if durchmesser <= 0 { return }
                let calculatesDurchmesser:Int = Int(round(durchmesser * 100))
                
                var artNoFormattedDiameter = calculatesDurchmesser.description
                
                if artNoFormattedDiameter.count > 4 {
                    showAlert(title: "Zu grosser Durchmesser", message: nil)
                    return
                }else {
                    while artNoFormattedDiameter.count < 4 {
                        artNoFormattedDiameter = "0" + artNoFormattedDiameter
                    }
                }
                
                print(drillScheme + artNoFormattedDiameter)
                openWerkzeuge(bestellNummer: drillScheme + artNoFormattedDiameter)
                addToHistory(history: History(value: drillScheme + artNoFormattedDiameter, inputType: .keyBoard))
            }
            
        }
        
        ac.addAction(submitAction)
        
        present(ac, animated: true)
        
    }
    
    @IBAction func closeCacheView(_ sender: UIButton) {
       closeCachedDataView()
    }
    
    @objc func closeCachedDataView() {
        UIView.animate(withDuration: 0.3) {
            self.cachedSchnittDatenView.alpha = 0
            self.darkBackgroundView.alpha = 0
        }
    }
    
    @IBAction func openCachedOnlineURL(_ sender: UIButton) {
        closeCacheView(UIButton())
        if let url = cachedOnlineURL {
            openTab(url: url)
        }
        
    }
    
    func openTab(url:URL, withWKWeb:Bool = true) {
        
        if withWKWeb {
            let vc = BrowserController(url: url, delegate: self)
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
            
        }else {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = false
            
            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
        
    }
    
    func addToHistory(history:History) {
        var loadedHistory = loadHistory(key: SaveKeys.historyKey.rawValue)
        loadedHistory.append(history)
        saveHistory(value: loadedHistory, key: SaveKeys.historyKey.rawValue)
    }
    
    func saveNewTool(tool:Tool) {
        werkzeuge[tool.toolNumber] = tool
        saveTools(value: werkzeuge, key: SaveKeys.toolLibKey.rawValue)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                setupUI()
            }
    }
    
    // Enable detection of shake motion
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let vc = FavoriteHistoryTableView(delegate: self)
            let feedback =  UIImpactFeedbackGenerator(style: .rigid)
            feedback.prepare()
            feedback.impactOccurred()
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }
    
    private func setupUI() {
        
        let shadowColor = traitCollection.userInterfaceStyle == .light ? UIColor.secondaryLabel.cgColor : UIColor.clear.cgColor
        view.backgroundColor = traitCollection.userInterfaceStyle == .light ? UIColor.secondarySystemGroupedBackground : UIColor.tertiarySystemGroupedBackground
        
        library.layer.cornerRadius = 20
        library.layer.shadowColor = shadowColor
        library.layer.shadowOpacity = 1
        library.layer.shadowOffset = .zero
        library.layer.shadowRadius = 20
        
        favoriten.layer.cornerRadius = 20
        favoriten.layer.shadowColor = shadowColor
        favoriten.layer.shadowOpacity = 1
        favoriten.layer.shadowOffset = .zero
        favoriten.layer.shadowRadius = 20
        
        codeInput.layer.cornerRadius = 20
        codeInput.layer.shadowColor = shadowColor
        codeInput.layer.shadowOpacity = 1
        codeInput.layer.shadowOffset = .zero
        codeInput.layer.shadowRadius = 20
        
        codeReader.layer.cornerRadius = 40
        codeReader.layer.shadowColor = shadowColor
        codeReader.layer.shadowOpacity = 1
        codeReader.layer.shadowOffset = .zero
        codeReader.layer.shadowRadius = 40
        
        toolExpert.layer.cornerRadius = 20
        toolExpert.layer.shadowColor = shadowColor
        toolExpert.layer.shadowOpacity = 1
        toolExpert.layer.shadowOffset = .zero
        toolExpert.layer.shadowRadius = 20
        
        fräser.layer.cornerRadius = 20
        fräser.layer.shadowColor = shadowColor
        fräser.layer.shadowOpacity = 1
        fräser.layer.shadowOffset = .zero
        fräser.layer.shadowRadius = 20
        
        bohrer.layer.cornerRadius = 20
        bohrer.layer.shadowColor = shadowColor
        bohrer.layer.shadowOpacity = 1
        bohrer.layer.shadowOffset = .zero
        bohrer.layer.shadowRadius = 20
        
        fastDrillSearch.layer.cornerRadius = 20
        
        cachedSchnittDatenView.layer.cornerRadius = 30
        cachedSchnittDatenView.isHidden = true
        
        cachedImage.layer.cornerRadius = 30
        cacheFinish.layer.cornerRadius = 20
        cacheWeb.layer.cornerRadius = 20
        cachedMaterialName.layer.cornerRadius = 20
        cachedMaterialName.layer.masksToBounds = true
        
        darkBackgroundView.isHidden = true
        
        darkBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeCachedDataView)))
    }
}

extension ToolNative: BrowserDelegate {
    @objc func didDismiss() {
        werkzeuge = loadTools(key: SaveKeys.toolLibKey.rawValue)
        barCodeReferences = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
    }
    
}

extension ToolNative: HistoryDelegate {
    func openToolWithNumber(toolCode: String, type:historyInputType) {
        
        if type == .barCode {
            if let toolCode2 = barCodeReferences[toolCode] {
                openWerkzeuge(bestellNummer: toolCode2)
                
            }else {
                werkzeugHinzufügen(toolCode: toolCode)
            }
        }else {
            openWerkzeuge(bestellNummer: toolCode)
        }
        
        
    }
    
    
}

extension ToolNative: ScannerDelegate{
    
    func foundContent(string: String, tag: String, tag2:Int) {
        
        if let toolCode = barCodeReferences[string] {
            openWerkzeuge(bestellNummer: toolCode)
            
        }else {
            werkzeugHinzufügen(isBarCode: true, toolCode: string)
        }
        
        addToHistory(history: History(value: string, inputType: .barCode))
    }
    
    func openWerkzeuge(bestellNummer:String) {
        if let tool = werkzeuge[bestellNummer] {
            
            
            if tool.materials.isEmpty {
                openTab(url: tool.defaultUrl)
            }else {
                
                var actions: [(String, UIAlertAction.Style)] = []
                
                tool.materials.forEach { (material) in
                    actions.append((material.materialName, .default))
                }
                
                actions.append(("Anderes Material wählen", .default))
                actions.append(("Abbrechen", .cancel))
                
                //self = ViewController
                Alerts.showActionsheet(viewController: self, title: "Material für \"\(bestellNummer)\" auswählen", message: nil, actions: actions) { (index) in
                    print("call action \(index)")
                    
                    if index > tool.materials.count {
                        // Abbrechen
                        print("Cancel")
                    }else if index == tool.materials.count { // Anderes Material wählen
                        self.openTab(url: tool.defaultUrl)
                        print("Other Material")
                    } else {
                        print("Show Material")
                        let material = tool.materials[index]
                        if let cachedImage = loadImageFromDirectory(fileName: material.pdfName ?? "") {
                            self.cachedSchnittDatenView.alpha = 0
                            self.cachedSchnittDatenView.isHidden = false
                            self.darkBackgroundView.alpha = 0
                            self.darkBackgroundView.isHidden = false
                            self.cachedOnlineURL = material.url
                            self.cachedImage.image = cachedImage
                            self.cachedMaterialName.text = material.materialName
                            UIView.animate(withDuration: 0.3) {
                                self.cachedSchnittDatenView.alpha = 1
                                self.darkBackgroundView.alpha = 0.65
                            }
                        }else {
                            self.openTab(url: material.url)
                        }
                        
                        
                    }
                    
                }
                
            }
            
            
            
            
        }else {
            werkzeugHinzufügen(toolCode: bestellNummer)
        }
    }
    
    func fügeWerkzeugHinzu(toolCode:String) {
        if let url = getSearchUrl(toolType: toolCode.isBohrer() ? .bohrer : .fräser, bestellNummer: toolCode) {
            print(url)
            self.openTab(url: url)
        }else {
            self.showAlert(title: "Werkzeug nicht gefunden", message: nil)
        }
    }
    
    func werkzeugHinzufügen(isBarCode:Bool = false, toolCode:String) {
        
        if !isBarCode {
            self.fügeWerkzeugHinzu(toolCode: toolCode)
        }
        
        let alert = UIAlertController(title: "Werkzeug nicht gefunden",
                                      message: nil,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Artikelnummer eingeben", style: .default, handler: { (action) in
            let ac = UIAlertController(title: "Werkzeugbezeichnung / Bestellnummer eingeben", message: nil, preferredStyle: .alert)
            ac.addTextField()
            ac.textFields![0].autocapitalizationType = .allCharacters
            ac.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            
            let submitAction = UIAlertAction(title: "Suchen", style: .default) { [self, unowned ac] _ in
                if let bez = ac.textFields![0].text?.trimmingCharacters(in: .whitespaces) {
                    if bez == "" { return }
                    self.barCodeReferences[toolCode] = bez
                    saveDict(value: self.barCodeReferences, key: SaveKeys.barCodeLibKey.rawValue)
                    openWerkzeuge(bestellNummer: bez)
                    addToHistory(history: History(value: bez, inputType: .keyBoard))
                }
                
            }
            
            ac.addAction(submitAction)
            
            self.present(ac, animated: true)
            
        }))
        
        
        alert.addAction(UIAlertAction(title: "Werkzeug suchen", style: .default, handler: { (action) in
            
            let alert = UIAlertController(title: "Werkzeugtyp",
                                          message: nil ,
                                          preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Fräser", comment: "Fräser"), style: .default) { (_) in
                
                self.openTab(url: fräserURL)
                
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Bohrer", comment: "Bohrer"), style: .default) { (_) in
                
                self.openTab(url: bohrerURL)
                
            })
            self.present(alert, animated: true, completion: nil)
            
        }))
        
        var actions: [(String, UIAlertAction.Style)] = []
        
        var toolArray = [String]()
        
        let tools = loadTools(key: SaveKeys.toolLibKey.rawValue)
        
        alert.addAction(UIAlertAction(title: "Mit Fräser verknüpfen", style: .default, handler: { (action) in
            
            tools.forEach { (tool) in
                if tool.value.toolType == .fräser {
                    toolArray.append(tool.value.toolNumber)
                }
            }
            toolArray.sort()
            
            toolArray.forEach { (tool) in
                actions.append((tool, .default))
            }
            
            actions.append(("Abbrechen", .cancel))
            
            //self = ViewController
            Alerts.showActionsheet(viewController: self, title: "Werkzeug auswählen", message: nil, actions: actions) { [self] (index) in
                print("call action \(index)")
                
                if index > toolArray.count - 1 {
                    return
                }else {
                    if let tool = tools[toolArray[index]] {
                        
                        self.barCodeReferences[toolCode] = tool.toolNumber
                        saveDict(value: self.barCodeReferences, key: SaveKeys.barCodeLibKey.rawValue)
                        DoneHUD.showInView(self.view, message: "Verknüpft")
                    }
                }
                
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Mit Bohrer verknüpfen", style: .default, handler: { (action) in
            
            tools.forEach { (tool) in
                if tool.value.toolType == .bohrer {
                    toolArray.append(tool.value.toolNumber)
                }
            }
            toolArray.sort()
            
            toolArray.forEach { (tool) in
                actions.append((tool, .default))
            }
            
            actions.append(("Abbrechen", .cancel))

            Alerts.showActionsheet(viewController: self, title: "Werkzeug auswählen", message: nil, actions: actions) { [self] (index) in
                print("call action \(index)")
                
                if index > toolArray.count - 1 {
                    return
                }else {
                        if let tool = tools[toolArray[index]] {
                            
                            self.barCodeReferences[toolCode] = tool.toolNumber
                            saveDict(value: self.barCodeReferences, key: SaveKeys.barCodeLibKey.rawValue)
                            DoneHUD.showInView(self.view, message: "Verknüpft")
                        }
                    
                    
                }
                
            }
        }))
        
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension UIViewController {
    func showAlert(title:String, message:String?) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

struct Tool: Codable {
    var toolNumber:String
    var defaultUrl:URL
    var toolType: ToolType
    var internalTooliD : String
    var materials:[Materials]
}

struct Materials:Codable {
    var materialName:String
    var url:URL
    var pdfName:String?
}

enum ToolType:String, Codable {
    case fräser = "fraeser"
    case bohrer = "bohrer"
}

func saveTools(value:[String:Tool],key:String)  {
    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(value) {
        let defaults = UserDefaults.standard
        defaults.setValue(encoded, forKey: key)
    }
}

func loadTools(key:String) -> [String:Tool] {
    let defaults = UserDefaults.standard
    if let savedPerson = defaults.object(forKey: key) as? Data {
        let decoder = JSONDecoder()
        if let loadedPerson = try? decoder.decode([String:Tool].self, from: savedPerson) {
            return loadedPerson
        }
    }
    return [:]
}

func saveDict(value:[String:String],key:String)  {
    let defaults = UserDefaults.standard
    defaults.setValue(value, forKey: key)
}

func loadDict(key:String) -> [String:String] {
    let defaults = UserDefaults.standard
    let savedBoolValue = defaults.value(forKey: key) as? [String:String]
    return savedBoolValue ?? [:]
}

func saveArray(value:[String], key:String)  {
    let defaults = UserDefaults.standard
    defaults.setValue(value, forKey: key)
}

func loadArray(key:String) -> [String] {
    let defaults = UserDefaults.standard
    let savedBoolValue = defaults.value(forKey: key) as? [String]
    return savedBoolValue ?? []
}

func saveString(value:String,key:String)  {
    let defaults = UserDefaults.standard
    defaults.setValue(value, forKey: key)
}

func loadString(key:String, defaultValue:String) -> String {
    let defaults = UserDefaults.standard
    let savedBoolValue = defaults.value(forKey: key) as? String
    return savedBoolValue ?? defaultValue
}

func getSearchUrl(toolType:ToolType, bestellNummer:String) -> URL? {
    if toolType == .fräser {
        return URL(string: "https://www.fraisa.com/toolexpert/2.0.21/#!/de/mode/search/tooltype/F/norm/normid/tab/zk/usecase/articleNo/\(bestellNummer)/d1/d2/d3/l1/l2/l3/z/r/b/H/L/deg45/CutMat/ShaftType/ToolType/performance_class/coating//beta/worktype/group/toolid/json/append/material/application/toolchoice")
        
    }else if toolType == .bohrer {
        return URL(string: "https://www.fraisa.com/toolexpert/2.0.21/#!/de/mode/search/tooltype/B/norm/normid/tab/zk/usecase/articleNo/\(bestellNummer)/d1/d2/d3/l1/l2/l3/z/r/b/H/L/deg45/CutMat/ShaftType/ToolType/performance_class/coating//beta/worktype/group/toolid/json/append/material/application/toolchoice")
    }
    return nil
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension String {
    func getValueBetween(_ string1:String, _ string2:String) -> String? {
        if let teil2 = self.components(separatedBy: string1)[safe: 1] {
            return teil2.components(separatedBy: string2)[safe: 0]
        }
        return nil
    }
}

extension URL {
    func urlAufbereiten(articleNo:String) -> URL? {
        let stringURL = self.description
        let teil1 = stringURL.components(separatedBy: "/articleNo/")
        let teil2 = teil1[1].components(separatedBy: "d1/")[1]
        
        return URL(string: teil1[0] + "/articleNo/" + articleNo + "/d1/" + teil2)
    }
}
