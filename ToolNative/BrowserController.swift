//
//  BrowserController.swift
//  ToolNative
//
//  Created by Marcin Kessler on 15.10.20.
//

import UIKit
import WebKit
import SafariServices
import Photos

class BrowserController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var webView = WKWebView()
    
    var url : URL?
    
    var progressBar = UIProgressView(progressViewStyle: .bar)
    
    var delegate:BrowserDelegate?
    
    var showDone = true
    
    fileprivate let lineLayer: CAShapeLayer = CAShapeLayer()
    
    let speichernButtonItem = UIBarButtonItem(title: "Speichern", style: .plain, target: self, action: #selector(saveToolAnwendung))
    
    var webViewIsShow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        if showDone {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        }
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .done, target: self, action: #selector(reloadButtonDidTap)), speichernButtonItem]
        
        view.backgroundColor = UIColor.tertiarySystemGroupedBackground
        
        setupLoadingIndicator()
        
        view.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            progressBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            progressBar.heightAnchor.constraint(equalToConstant: 2),
        ])
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            webView.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 1),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])
        
        webView.alpha = 0
        
        webView.customUserAgent = "Firefox/81.0"
        
        webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        webView.backgroundColor = UIColor.tertiarySystemGroupedBackground
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        if let url = url {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            webView.load(request)
            
        }
        
        webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
        enableDisableSave()
        
        if let url = url {
            saveWebHistory(url: url)
        }
        
    }
    
    @objc func reloadButtonDidTap() {
        if let _ = webView.url {
            webView.reload()
        } else {
            if let url = url {
                webView.load(URLRequest(url: url))
            }
        }
    }
    
    @objc func saveToolAnwendung() {
        if webView.url?.description.contains("cuttingcondition") == true {
            saveAnwendung()
        }else if webView.url?.description.contains("http://www.fraisa.com/toolexpert-ax-fps/1.0.17/#!/de-DE") == true{
            showAlert(title: "Toolexpert AX-FPS wird nicht unterstützt", message: nil)
        }else {
            saveTool()
        }
        
        
    }
    
    @objc func saveAnwendung() {
        print("saveAnwendung")
        
        if let url = webView.url {
            
            let stringURL = url.description
            
            if var articleNo = stringURL.getValueBetween("/articleNo/", "/") {
                if articleNo == "" || articleNo == "d1" {
                    
                    if let internalNumber = url.description.getValueBetween("/toolid/", "/") {
                        let toolLib = loadTools(key: SaveKeys.toolLibKey.rawValue)
                        
                        toolLib.forEach { (key, value) in
                            if value.internalTooliD == internalNumber {
                                articleNo = value.toolNumber
                            }
                        }
                    }
                    
                    if articleNo == "" || articleNo == "d1" {
                        var actions: [(String, UIAlertAction.Style)] = []
                        
                        var toolArray = [String]()
                        
                        let tools = loadTools(key: SaveKeys.toolLibKey.rawValue)
                        
                        tools.forEach { (tool) in
                            toolArray.append(tool.value.toolNumber)
                            
                        }
                        toolArray.sort()
                        
                        toolArray.forEach { (tool) in
                            actions.append((tool, .default))
                        }
                        
                        actions.append(("Abbrechen", .cancel))
                        
                        //self = ViewController
                        Alerts.showActionsheet(viewController: self, title: "Werkzeug auswählen", message: nil, actions: actions) { [self] (index) in
                            print("call action \(index)")
                            
                            if index > tools.count - 1 {
                                return
                            }else {
                                if let tool = tools[toolArray[index]] {
                                    
                                    self.saveToolWithMaterial(articleNo: tool.toolNumber)
                                    
                                }
                            }
                            
                        }
                        
                    }else {
                        print("saveToolWithMaterial")
                        saveToolWithMaterial(articleNo: articleNo)
                    }
                    
                }else {
                    print("saveToolWithMaterial")
                    saveToolWithMaterial(articleNo: articleNo)
                }
                
            }else {
                showAlert(title: "Fehler aufgetreten", message: "Es ist ein unbekannter Fehler aufgetreten. Versuchen Sie es später erneut")
            }
            
        }else {
            showAlert(title: "Fehler aufgetreten", message: "Es ist ein unbekannter Fehler aufgetreten. Versuchen Sie es später erneut")
        }
        
        
    }
    
    func saveToolWithMaterial(articleNo:String) {
        let ac = UIAlertController(title: "Material", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        ac.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        
        ac.addAction(UIAlertAction(title: "Speichern", style: .default) { [self, unowned ac] _ in
            if let bez = ac.textFields![0].text{
                if bez == "" { showAlert(title: "Kein Material angegeben", message: nil); return }
                
                
                addMaterialToTool(material: bez, articleNo: articleNo)
            }
            
        })
        
        ac.addAction(UIAlertAction(title: "Material wählen", style: .default, handler: { (action) in
            
            
            var allMaterials = Set<String>()
            
            let toolLibrary = loadTools(key: SaveKeys.toolLibKey.rawValue)
            
            toolLibrary.forEach { (tool) in
                tool.value.materials.forEach { (materials) in
                    allMaterials.insert(materials.materialName)
                }
            }
            
            let allMaterialsSorted = Array(allMaterials).sorted()
            
            var actions: [(String, UIAlertAction.Style)] = []
            allMaterialsSorted.forEach { (materialName) in
                actions.append((materialName, .default))
            }
            
            actions.append(("Abbrechen", .cancel))
            
            //self = ViewController
            Alerts.showActionsheet(viewController: self, title: "Material auswählen", message: nil, actions: actions) { [self] (index) in
                print("call action \(index)")
                
                if index > allMaterialsSorted.count - 1 {
                    return
                }else {
                    let materialName = allMaterialsSorted[index]
                    addMaterialToTool(material: materialName, articleNo: articleNo)
                }
                
            }
            
            self.present(ac, animated: true)
        }))
        self.present(ac, animated: true, completion: nil)
    }
    
    func addMaterialToTool(material:String, articleNo:String) {
        
        
        
        var tools = loadTools(key: SaveKeys.toolLibKey.rawValue)
        if var newTool = tools[articleNo] {
            
            var duplicated = false
            
            newTool.materials.forEach { (mat) in
                if mat.materialName == material { duplicated = true }
            }
            
            if duplicated {
                showAlert(title: "Für dieses Werkzeg existiert dieses Material bereits", message: "")
                return
            }
            let config = WKSnapshotConfiguration()
            config.rect = CGRect(x: 20, y: 60, width: self.webView.frame.size.width - 40, height: 400)
            
            drawRect(nil)
            
            var time = 3
            
            let timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            webView.addSubview(timeLabel)
            timeLabel.font = UIFont.monospacedSystemFont(ofSize: 40, weight: .heavy)
            timeLabel.textColor = .systemRed
            timeLabel.textAlignment = .center
            
            timeLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                timeLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                timeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            ])
            timeLabel.text = time.description
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                
                if time == 1 {
                    timer.invalidate()
                    
                    self.clearRect()
                    timeLabel.removeFromSuperview()
                    
                    
                    self.webView.takeSnapshot(with: config) { image, error in
                        if image != nil {
                            let pdfName = (articleNo + material).sha256()
                            _ = image?.saveToDirectory(imageName: pdfName)
                            newTool.materials.append(Materials(materialName: material, url: self.webView.url?.urlAufbereiten(articleNo: newTool.toolNumber) ?? self.webView.url!, pdfName: pdfName))
                            tools[articleNo] = newTool
                            saveTools(value: tools, key: SaveKeys.toolLibKey.rawValue)
                            DoneHUD.showInView(self.webView, message: "Gespeichert")
                            self.enableDisableSaveButton(isEnabled: false)
                        }
                    }
                    
                    return
                }
                
                time -= 1
                timeLabel.text = time.description
            }
            
        }else {
            showAlert(title: "Werkzeug existiert noch nicht. Bitte zuerst hinzufügen", message: nil)
        }
        
    }
    
    @objc func dismissSelf() {
        self.dismiss(animated: true) { [self] in
            self.delegate?.didDismiss()
        }
    }
    @objc func saveTool(automatic:Bool = false) {

        if let url = webView.url {
            
            let stringURL = url.description
            
            if let tType = stringURL.getValueBetween("/tooltype/", "/norm") {
                if let articleNo = stringURL.getValueBetween("/articleNo/", "/") {
                    if articleNo == "" || articleNo == "d1" {
                        if automatic { return }
                        let alert = UIAlertController(title: NSLocalizedString("Artikelnummer eingeben", comment: "Artikelnummer eingeben"),
                                                      message: nil ,
                                                      preferredStyle: .alert)
                        alert.addTextField()
                        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
                        let submitAction = UIAlertAction(title: "Speichern", style: .default) { [self, unowned alert] _ in
                            if let bez = alert.textFields![0].text {
                                saveAsNewWerkzeug(toolNumber: bez, url: url, toolType: .fräser)
                            }
                        }
                        alert.addAction(submitAction)
                        present(alert, animated: true)
                        
                    }else {
                        if tType == "F" {
                            saveAsNewWerkzeug(toolNumber: articleNo, url: url, toolType: .fräser, automatic: automatic)
                        }else if tType == "B" {
                            saveAsNewWerkzeug(toolNumber: articleNo, url: url, toolType: .bohrer, automatic: automatic)
                        }
                        
                        enableDisableSaveButton(isEnabled: false)
                    }
                    
                }else {
                    showAlert(title: "Fehler aufgetreten", message: "Es ist ein unbekannter Fehler aufgetreten. Versuchen Sie es später erneut")
                }
            }else {
                showAlert(title: "Fehler aufgetreten", message: "Es ist ein unbekannter Fehler aufgetreten. Versuchen Sie es später erneut")
            }
            
        }
        
    }
    
    func saveAsNewWerkzeug(toolNumber:String, url:URL, toolType:ToolType, automatic:Bool = false) {
        
        var toolLib = loadTools(key: SaveKeys.toolLibKey.rawValue)
        toolLib[toolNumber] = Tool(toolNumber: toolNumber, defaultUrl: url.urlAufbereiten(articleNo: toolNumber) ?? url, toolType: toolType, internalTooliD: url.description.getValueBetween("/toolid/", "/") ?? "", materials: [])
        saveTools(value: toolLib, key: SaveKeys.toolLibKey.rawValue)
        
        var delayToBarcode:Double = 1
        if automatic {
            let delayInSeconds:Double = 1
            delayToBarcode += delayInSeconds
            let popTime = DispatchTime.now() + Double(Int64(delayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
                
                DoneHUD.showInView(self.view, message: "Hinzugefügt")
                
            }
        }else {
            DoneHUD.showInView(self.view, message: "Hinzugefügt")
        }
        
        if loadDict(key: SaveKeys.barCodeLibKey.rawValue).someKey(forValue: toolNumber) != nil { return }
        
        
        let popTime = DispatchTime.now() + Double(Int64(delayToBarcode * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
            
            let alert = UIAlertController(title: "Barcode hinzufügen?",
                                          message: "Möchtest du einen Barcode für das Werkzeug hinzufügen?",
                                          preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Nicht Hinzufügen", style: .cancel))
            alert.addAction(UIAlertAction(title: "Hinzufügen", style: .default, handler: { [self] (action) in
                let vc = ScannerViewController()
                vc.delegate = self
                vc.tag = toolNumber
                self.present(vc, animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        }
        
        
    }
    
    func drawRect(_ completion: (() -> Void)?) {

        initialize()
        
        var frm: CGRect = webView.frame
        frm.origin.x = frm.origin.x + 20
        frm.origin.y = frm.origin.y + webView.frame.size.height - 60 - 60
        frm.size.width = webView.frame.size.width - 40
        frm.size.height = 400
        let canvasFrame = frm
        //        let canvasFrame = CGRect(
        //            x: 20,
        //            y: view.frame.size.height,
        //            width: view.frame.size.width - 40,
        //            height: 450)
        let path = UIBezierPath()
        path.move(
            to: CGPoint(x: canvasFrame.origin.x, y: canvasFrame.origin.y))
        path.addLine(
            to: CGPoint(x: canvasFrame.origin.x + canvasFrame.width, y: canvasFrame.origin.y))
        path.addLine(
            to: CGPoint(x: canvasFrame.origin.x + canvasFrame.width, y: canvasFrame.origin.y - canvasFrame.height))
        path.addLine(
            to: CGPoint(x: canvasFrame.origin.x, y: canvasFrame.origin.y - canvasFrame.height))
        path.addLine(
            to: CGPoint(x: canvasFrame.origin.x, y: canvasFrame.origin.y))
        self.lineLayer.frame = self.view.bounds
        self.lineLayer.isGeometryFlipped = true
        self.lineLayer.path = path.cgPath
        
        view.layer.addSublayer(self.lineLayer)
        self.animate(completion)
    }
    
    fileprivate func initialize() {
        // Initialize properties
        self.view.clipsToBounds = true
        
        // Set default setting to line
        self.lineLayer.fillColor = UIColor.clear.cgColor
        self.lineLayer.anchorPoint = CGPoint(x: 0, y: 0)
        self.lineLayer.lineJoin = .round
        self.lineLayer.lineCap = .round
        self.lineLayer.contentsScale = self.view.layer.contentsScale
        self.lineLayer.lineWidth = 3
        self.lineLayer.strokeColor = UIColor.systemRed.cgColor
        
    }
    
    fileprivate func animate(_ completion: (() -> Void)?) {
        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.duration = 0.4
        pathAnimation.fromValue = NSNumber(value: 0 as Float)
        pathAnimation.toValue = NSNumber(value: 1 as Float)
        CATransaction.begin()
        if let completion = completion {
            CATransaction.setCompletionBlock(completion)
        }
        self.lineLayer.add(pathAnimation, forKey:"strokeEndAnimation")
        CATransaction.commit()
    }
    
    func clearRect() {
        self.lineLayer.removeFromSuperlayer()
        self.lineLayer.removeAllAnimations()
        self.lineLayer.path = nil
    }
    
    init(url:URL, delegate:BrowserDelegate?, showDone:Bool = true) {
        self.url = url
        self.delegate = delegate
        self.showDone = showDone
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            print(Float(webView.estimatedProgress))
            progressBar.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress == 1 {
                enableDisableSave()
            }
            
            if webView.estimatedProgress > 0.55 && webViewIsShow == false {
                webViewIsShow = true
                UIView.animate(withDuration: 0.5) {
                    self.webView.alpha = 1
                }
            }
            
        }
        if keyPath == "title" {
            if let title = webView.title {
                print(title)
            }
        }
        if keyPath == "URL" {
            if let url = webView.url {
                print("Url change:",url)
                enableDisableSave()
                saveWebHistory(url:url)
            }
        }
    }

    func enableDisableSave() {
        var saveIsEnabled = false
        if webView.url?.description.contains("/append/material") == true &&
            (webView.url?.description.contains("toolchoice") == false && webView.url?.description.contains("/append/material/application") == false)
        {
            saveIsEnabled = true
            
            let toolLib = loadTools(key: SaveKeys.toolLibKey.rawValue)
            
            if webView.url?.description.contains("/append/material") == true {
                if let articleNo = webView.url?.description.getValueBetween("/articleNo/", "/") {
                    if let _ = toolLib[articleNo] {
                        saveIsEnabled = false
                    }
                }
                
                if let toolID = webView.url?.description.getValueBetween("/toolid/", "/") {
                    toolLib.forEach { (_, tool) in
                        if tool.internalTooliD == toolID {
                            saveIsEnabled = false
                        }
                    }
                }
                
                if saveIsEnabled {
                    saveTool(automatic: true)
                }
            }
            
            
        }
        
        if webView.url?.description.contains("cuttingcondition") == true  {
            saveIsEnabled = true
        }
        
        enableDisableSaveButton(isEnabled: saveIsEnabled)

    }
    
    func enableDisableSaveButton(isEnabled:Bool) {
        navigationItem.rightBarButtonItems?[safe: 1]?.isEnabled = isEnabled
    }
    
    func saveWebHistory(url:URL) {
        var oldHistory = loadSafariHistory(key: SaveKeys.safariHistoryKey.rawValue)
        
        var toolID :String?
        var internalToolID :String?
        var toolType:webToolType = .undefined
        var webPageHistoryType:webHistoryPageType = .undefined
        
        if let articleNo = webView.url?.description.getValueBetween("/articleNo/", "/") {
            if articleNo != "d1" { toolID = articleNo }
        }
        
        if let intToolID = webView.url?.description.getValueBetween("/toolid/", "/") {
            if intToolID != "append" { internalToolID = intToolID }
        }
        
        if let tType = url.description.getValueBetween("/tooltype/", "/norm") {
            if tType == "B" { toolType = .bohrer} else { toolType = .fräser }
        }
        
        if url.description == "https://www.fraisa.com/toolexpert/2.0.21/#!/de/start" { webPageHistoryType = .toolSearchMask} else
        if url.description.contains("/append/search") { webPageHistoryType = .toolSearchMask } else
        if url.description.contains("/application/toolchoice") && !url.description.contains("/cuttingcondition") { webPageHistoryType = .toolChoice } else
        if url.description.contains("/append/material") && !url.description.contains("application") { webPageHistoryType = .materialChoice }  else
        if url.description.contains("/material/application") && !url.description.contains("toolchoice") && !url.description.contains("cuttingcondition") { webPageHistoryType = .drillLength }  else
        if url.description.contains("/toolchoice/cuttingcondition") { webPageHistoryType = .finalCutData }
        
        
        oldHistory.append(WebHistory(toolID: toolID, internalToolID: internalToolID, url: url, pageType: webPageHistoryType, toolType: toolType))
        saveSafariHistory(value: oldHistory, key: SaveKeys.safariHistoryKey.rawValue)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "UPS ;)", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    private func setupLoadingIndicator() {
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 0),
            activityIndicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -40)
        ])
        
        let loadLabel = UILabel()
        loadLabel.text = "Laden ..."
        loadLabel.textAlignment = .center
        loadLabel.font = UIFont.boldSystemFont(ofSize: 17)
        loadLabel.lineBreakMode = .byWordWrapping
        loadLabel.numberOfLines = 0
        loadLabel.textColor = .secondaryLabel
        view.addSubview(loadLabel)
        
        loadLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            loadLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            loadLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10),
        ])
    }
    
}

protocol BrowserDelegate {
    func didDismiss()
}

extension BrowserController:ScannerDelegate {
    func foundContent(string: String, tag: String, tag2:Int) {
        
        if tag != "" { // Save Tool
            var ref = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
            ref[string] = tag
            saveDict(value: ref, key: SaveKeys.barCodeLibKey.rawValue)
            DoneHUD.showInView(self.view, message: "Barcode hinzugefügt")
        }
    }
    
    
}

class Alerts {
    static func showActionsheet(viewController: UIViewController, title: String, message: String?, actions: [(String, UIAlertAction.Style)], completion: @escaping (_ index: Int) -> Void) {
        let alertViewController = UIAlertController(title: title, message: message == "" ? nil : message, preferredStyle: .actionSheet)
        for (index, (title, style)) in actions.enumerated() {
            let alertAction = UIAlertAction(title: title, style: style) { (_) in
                completion(index)
            }
            alertViewController.addAction(alertAction)
        }
        viewController.present(alertViewController, animated: true)
    }
}
