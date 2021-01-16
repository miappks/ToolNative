//
//  ImageViewer.swift
//  ToolNative
//
//  Created by Marcin Kessler on 16.10.20.
//

import UIKit

class ImageViewer: UIViewController {
    
    var image = UIImage()
    var url:URL?
    var materialName = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        view.backgroundColor = .secondarySystemGroupedBackground
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10),
        ])
        
        if let _ = url {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openUrl))
        }
        
        title = materialName
        
    }
    
    @objc func openUrl() {
        let vc = BrowserController(url: url!, delegate: nil)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    init(image: UIImage, url:URL, materialName:String) {
        self.image = image
        self.url = url
        self.materialName = materialName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
