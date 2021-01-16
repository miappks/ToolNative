//
//  PDFGenerator.swift
//  ToolNative
//
//  Created by Marcin Kessler on 16.10.20.
//

import Foundation
import UIKit
import WebKit

//MARK:-UIView
extension UIView {
    
    // Export pdf from Save pdf in drectory and return pdf file path
    func exportAsPdfFromView(pdfName:String) -> String {
        
        let pdfPageFrame = self.bounds
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageFrame, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageFrame, nil)
        guard let pdfContext = UIGraphicsGetCurrentContext() else { return "" }
        self.layer.render(in: pdfContext)
        UIGraphicsEndPDFContext()
        return self.saveViewPdf(data: pdfData, pdfName: pdfName)
        
    }
    
    // Save pdf file in document directory
    func saveViewPdf(data: NSMutableData, pdfName:String) -> String {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = paths[0]
        let pdfPath = docDirectoryPath.appendingPathComponent("\(pdfName).pdf")
        if data.write(to: pdfPath, atomically: true) {
            return pdfPath.path
        } else {
            return ""
        }
    }
}

//MARK:-WKWebView
extension WKWebView {
    
    // Call this function when WKWebView finish loading
    func exportAsPdfFromWebView(pdfName:String) -> String {
        let pdfData = createPdfFile(printFormatter: self.viewPrintFormatter())
        return self.saveWebViewPdf(data: pdfData, pdfName: pdfName)
    }
    
    func createPdfFile(printFormatter: UIViewPrintFormatter) -> NSMutableData {
        
        let originalBounds = self.bounds
        self.bounds = CGRect(x: originalBounds.origin.x, y: bounds.origin.y, width: self.bounds.size.width, height: self.scrollView.contentSize.height)
        let pdfPageFrame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.scrollView.contentSize.height)
        let printPageRenderer = UIPrintPageRenderer()
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        printPageRenderer.setValue(NSValue(cgRect: UIScreen.main.bounds), forKey: "paperRect")
        printPageRenderer.setValue(NSValue(cgRect: pdfPageFrame), forKey: "printableRect")
        self.bounds = originalBounds
        return printPageRenderer.generatePdfData()
    }
    
    // Save pdf file in document directory
    func saveWebViewPdf(data: NSMutableData, pdfName:String) -> String {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = paths[0]
        let pdfPath = docDirectoryPath.appendingPathComponent("\(pdfName).pdf")
        if data.write(to: pdfPath, atomically: true) {
            return pdfPath.path
        } else {
            return ""
        }
    }
}

extension UIPrintPageRenderer {
    
    func generatePdfData() -> NSMutableData {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil)
        self.prepare(forDrawingPages: NSMakeRange(0, self.numberOfPages))
        let printRect = UIGraphicsGetPDFContextBounds()
        for pdfPage in 0..<self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: pdfPage, in: printRect)
        }
        UIGraphicsEndPDFContext();
        return pdfData
    }
}

//MARK:-WKWebView
extension UITableView {
    
    // Export pdf from UITableView and save pdf in drectory and return pdf file path
    func exportAsPdfFromTable(pdfName:String) -> String {
        
        let originalBounds = self.bounds
        self.bounds = CGRect(x:originalBounds.origin.x, y: originalBounds.origin.y, width: self.contentSize.width, height: self.contentSize.height)
        let pdfPageFrame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.contentSize.height)
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageFrame, nil)
        UIGraphicsBeginPDFPageWithInfo(pdfPageFrame, nil)
        guard let pdfContext = UIGraphicsGetCurrentContext() else { return "" }
        self.layer.render(in: pdfContext)
        UIGraphicsEndPDFContext()
        self.bounds = originalBounds
        // Save pdf data
        return self.saveTablePdf(data: pdfData, pdfName: pdfName)
        
    }
    
    // Save pdf file in document directory
    func saveTablePdf(data: NSMutableData, pdfName:String) -> String {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = paths[0]
        let pdfPath = docDirectoryPath.appendingPathComponent("\(pdfName).pdf")
        if data.write(to: pdfPath, atomically: true) {
            return pdfPath.path
        } else {
            return ""
        }
    }
}


extension UIImage {
    // Save pdf file in document directory
    func saveToDirectory(imageName:String) -> String {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDirectoryPath = paths[0]
        let pdfPath = docDirectoryPath.appendingPathComponent("\(imageName).png")
        guard let data = self.pngData() else { return ""}
        do {
            try data.write(to: pdfPath, options: .atomic)
            return pdfPath.path
        } catch  {
            return ""
        }
        
    }
}

func deleteFileFromDirectory(imageName:String) {
    
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let docDirectoryPath = paths[0]
    let pdfPath = docDirectoryPath.appendingPathComponent("\(imageName).png")
    do {
        try FileManager.default.removeItem(at: pdfPath)
    } catch  {
    }
    
}

var documentsUrl: URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}

func loadImageFromDirectory(fileName: String) -> UIImage? {
    let fileURL = documentsUrl.appendingPathComponent(fileName + ".png")
    do {
        let imageData = try Data(contentsOf: fileURL)
        return UIImage(data: imageData)
    } catch {
        print("Error loading image : \(error)")
    }
    return nil
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
