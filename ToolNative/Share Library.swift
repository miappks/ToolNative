//
//  Share Library.swift
//  ToolNative
//
//  Created by Marcin Kessler on 18.10.20.
//

import Foundation
import UIKit

public struct SchnittdatenImage: Codable {

    public let photo: Data
    

    public init(photo: UIImage) {
        self.photo = photo.pngData()!
    }
}

struct ExportLibraryData : Codable {
    var toolLibrary : [String:Tool]
    var barCodes : [String:String]
    var imageData : [String:SchnittdatenImage]
    var exportType : exportType
}

enum exportType : String, Codable {
    case barcodeLibrary = "barcodeLibrary"
    case toolLibrary = "toolLibrary"
    case barcodeAndToolLibrary = "barcodeAndToolLibrary"
}

func importData(data: Data) -> ExportLibraryData? {
    let decoder = JSONDecoder()

    if let jsonPetitions = try? decoder.decode(ExportLibraryData.self, from: data) {
        return jsonPetitions
    }
    return nil
}

func exportData(data: ExportLibraryData) -> Data? {
    let encoder = JSONEncoder()

    if let exportData = try? encoder.encode(data) {
        return exportData
    }
    return nil
}

func exportToFileURL(exportFile: ExportLibraryData) -> URL? {
    
    guard let data = exportData(data: exportFile) else {
        return nil
    }
    
    guard let path = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
    }
    
    let saveFileURL = path.appendingPathComponent("/ToolLibrary.toolLib")
    do {
        try data.write(to: saveFileURL, options: .atomic)
        return saveFileURL
    } catch  {
        return nil
    }
    
}

func importToolLibrary(from url: URL) -> ExportLibraryData? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    
    // Add the new note to your persistent storage here
    do {
        try FileManager.default.removeItem(at: url)
    } catch {
        print("Failed to remove item from Inbox")
    }
    
    return importData(data: data)
}


//@IBAction func share() {
//    guard let url = exportToFileURL(note: currentNote) else {
//            return
//    }
//
//    let activityViewController = UIActivityViewController(
//        activityItems: ["You can add some text or other items here", url],
//        applicationActivities: nil)
//    present(activityViewController, animated: true, completion: nil)
//}
