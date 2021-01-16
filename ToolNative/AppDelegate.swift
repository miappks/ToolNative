//
//  AppDelegate.swift
//  ToolNative
//
//  Created by Marcin Kessler on 15.10.20.
//

import UIKit
import MBProgressHUD

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        var newTools = [String : Tool]()
//        let t = loadTools(key: SaveKeys.toolLibKey.rawValue)
//        t.forEach { (key, value) in
//            
//            var newTool = value
//            
//            newTool.defaultUrl = urlErneuern(newTool.defaultUrl) ?? fraisaExpertHomeURL
//            
//            var newMaterial = [Materials]()
//            
//            newTool.materials.forEach { (material) in
//                var newMat = material
//                newMat.url = urlErneuern(newMat.url) ?? fraisaExpertHomeURL
//                newMaterial.append(newMat)
//            }
//            
//            newTool.materials = newMaterial
//            
//            newTools[key] = newTool
//            
//        }
//        
//        saveTools(value: newTools, key: SaveKeys.toolLibKey.rawValue)
        
        window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        return true
    }
    
    func urlErneuern(_ url:URL) -> URL? {
        let newUrl = url.absoluteString
        let teil1 = newUrl.components(separatedBy: "/append/")
        return URL(string: teil1[0] + "/json/append/" + teil1[1])
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.pathExtension == "toolLib" {
            print("Import file")
            window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            
            let importedToolLibrary = importToolLibrary(from: url)
            
            guard let toolLib = importedToolLibrary else {
                window?.rootViewController?.showAlert(title: "Fehler beim Importieren der Bibliothek aufgetreten", message: "Die Datei ist beschädigt oder besitzt ein altes Format")
                return true
            }
            
            switch toolLib.exportType {
            case .toolLibrary:
                
                importStatementForToolLibrary(url: url, toolLib: toolLib)
                
                
                //MARK:- Import Barcode Library
            case .barcodeLibrary:
                
                importStatementForBarcodeLibrary(url: url, toolLib: toolLib)
                
            case .barcodeAndToolLibrary:
                
                let alert = UIAlertController(title: (url.lastPathComponent.components(separatedBy: ".")[safe: 0] ?? "Werkzeugbibliothek") + " importieren", message: "Was möchtest du importieren?" , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
                alert.addAction(UIAlertAction(title: "Werkzeugbibliothek", style: .default) { [self] (_) in
                    
                    importStatementForToolLibrary(url: url, toolLib: toolLib)
                    
                })
                alert.addAction(UIAlertAction(title: "Barcodebibliothek", style: .default) { [self] (_) in
                    
                    importStatementForBarcodeLibrary(url: url, toolLib: toolLib)
                    
                })
                alert.addAction(UIAlertAction(title: "Beide", style: .default) { [self] (_) in
                    
                    importStatementForToolLibrary(url: url, toolLib: toolLib, addBove: true)
                    
                })
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                
                
            }
            
            

        }
        return true
    }
    
    func importStatementForBarcodeLibrary(url:URL, toolLib:ExportLibraryData) {
        
        if loadDict(key: SaveKeys.barCodeLibKey.rawValue).isEmpty {
            saveDict(value: toolLib.barCodes, key: SaveKeys.barCodeLibKey.rawValue)
            self.erfolgreichImportiert()
            return
        }
        
        let alert = UIAlertController(title: "Barcode Bibliothek importieren?",
                                      message: "Möchtest du die Barcodebibliothek zu deiner hinzufügen oder deine ersetzen?" ,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Hinzufügen", style: .default) { (_) in
            
            var oldBarcodeLibrary = loadDict(key: SaveKeys.barCodeLibKey.rawValue)
            
            let alert = UIAlertController(title: "Welche Bibliothek möchtest du bevorzugen?",
                                          message: "Möchtest du bei Dublikaten deine Barcodes oder die importierten speichern" ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: "Vorhandene Barcodes", style: .default) { (_) in
                
                toolLib.barCodes.forEach { (key, value) in
                    if let _ = oldBarcodeLibrary[key] {
                        // Nicht importieren da vorhanden
                    }else {
                        oldBarcodeLibrary[key] = value
                    }
                }
                saveDict(value: oldBarcodeLibrary, key: SaveKeys.barCodeLibKey.rawValue)
                self.erfolgreichImportiert()
            })
            alert.addAction(UIAlertAction(title: "Importierte Barcodes", style: .default) { (_) in
                toolLib.barCodes.forEach { (key, value) in
                    oldBarcodeLibrary[key] = value
                    
                }
                saveDict(value: oldBarcodeLibrary, key: SaveKeys.barCodeLibKey.rawValue)
                self.erfolgreichImportiert()
            })
            
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            
            
        })
        
        alert.addAction(UIAlertAction(title: "Ersetzen", style: .destructive) { (_) in
            
            let alert = UIAlertController(title: "Werkzeugbibliothek ersetzen",
                                          message: "Alle deine Daten gehen unwiderruflich verloren",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: "Ersetzen", style: .destructive) { (_) in
                saveDict(value: toolLib.barCodes, key: SaveKeys.barCodeLibKey.rawValue)
                self.erfolgreichImportiert()
            })
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            
        })
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func importStatementForToolLibrary(url:URL, toolLib:ExportLibraryData, addBove:Bool = false) {
        
        if loadTools(key: SaveKeys.toolLibKey.rawValue).isEmpty {
            importAndSaveToolLibrary(toolLib: toolLib, meineBevorzugen: false, addBove: addBove, url: url)
            return
        }
        
        let alert = UIAlertController(title: (url.lastPathComponent.components(separatedBy: ".")[safe: 0] ?? "Werkzeugbibliothek") + " importieren", message: "Möchtest du die Werkzeugbibliothek zu deiner hinzufügen oder deine ersetzen?" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Hinzufügen", style: .default) { (_) in
            
            let alert = UIAlertController(title: "Welche Bibliothek möchtest du bevorzugen?",
                                          message: "Möchtest du bei Dublikaten deine Werkzeuge oder die importierten speichern" ,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: "Vorhandene Bibliothek", style: .default) { (_) in
                self.importAndSaveToolLibrary(toolLib: toolLib, meineBevorzugen: true, url: url)
                
            })
            alert.addAction(UIAlertAction(title: "Importierte Bibliothek", style: .default) { (_) in
                self.importAndSaveToolLibrary(toolLib: toolLib, meineBevorzugen: false, addBove: addBove, url: url)
                
            })
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        })
        alert.addAction(UIAlertAction(title: "Ersetzen", style: .destructive) { (_) in
            
            let alert = UIAlertController(title: "Werkzeugbibliothek ersetzen",
                                          message: "Alle deine Daten gehen unwiderruflich verloren",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
            alert.addAction(UIAlertAction(title: "Ersetzen", style: .destructive) { (_) in
                
                saveTools(value: [:], key: SaveKeys.toolLibKey.rawValue)
                self.importAndSaveToolLibrary(toolLib: toolLib, meineBevorzugen: false, addBove: addBove, url: url)
                
            })
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            
            
        })
        
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func importAndSaveToolLibrary(toolLib:ExportLibraryData, meineBevorzugen:Bool, addBove:Bool = false, url:URL) {
        
        let hud = MBProgressHUD.showAdded(to: window?.rootViewController?.view ?? UIView(), animated: true)
        hud.mode = .indeterminate
        hud.label.text = "Importieren ..."
        
        if meineBevorzugen {
            let oldLib = loadTools(key: SaveKeys.toolLibKey.rawValue)
            let importedToolLibrary = toolLib.toolLibrary
            var newToolLibrary = oldLib
            importedToolLibrary.forEach { (key, value) in
                
                if let _ = oldLib[key] {
                    // Not import because contain
                }else {
                    newToolLibrary[key] = value
                    value.materials.forEach { (material) in
                        if let imageName = material.pdfName {
                            if let imageData = toolLib.imageData[imageName]?.photo {
                                if let image = UIImage(data: imageData) {
                                    _ = image.saveToDirectory(imageName: imageName)
                                }
                            }
                        }
                    }
                }
                
            }
            saveTools(value: newToolLibrary, key: SaveKeys.toolLibKey.rawValue)
            hud.hide(animated: true)
            if addBove {
                importStatementForBarcodeLibrary(url: url, toolLib: toolLib)
                return
            }
            erfolgreichImportiert()
            
            return
        }
        let importedToolLibrary = toolLib.toolLibrary
        var newToolLibrary = loadTools(key: SaveKeys.toolLibKey.rawValue)
        importedToolLibrary.forEach { (key, value) in
            newToolLibrary[key] = value
            value.materials.forEach { (material) in
                if let imageName = material.pdfName {
                    if let imageData = toolLib.imageData[imageName]?.photo {
                        if let image = UIImage(data: imageData) {
                            _ = image.saveToDirectory(imageName: imageName)
                        }
                    }
                }
            }
        }
        saveTools(value: newToolLibrary, key: SaveKeys.toolLibKey.rawValue)
        hud.hide(animated: true)
        if addBove {
            importStatementForBarcodeLibrary(url: url, toolLib: toolLib)
            return
        }
        erfolgreichImportiert()
    }
    
    
    func erfolgreichImportiert() {
        if let presenterView = window?.rootViewController?.view {
            DoneHUD.showInView(presenterView, message: "Erfolgreich importiert")
        }
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("reloadData"), object: nil)
        
    }
}



