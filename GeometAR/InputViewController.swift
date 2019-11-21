//
//  InputViewController.swift
//  GeometAR
//
//  Created by Birnbaum on 27.04.18.
//  Copyright © 2018 IDMI. All rights reserved.
//

import UIKit


class InputViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var gkArray = [UIImage]()
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        blurView.layer.cornerRadius = 20
        blurView.layer.masksToBounds = true
        blurView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        gkArray =  [
                        UIImage(named: "sphere")!,
                        UIImage(named: "quader")!,
                        UIImage(named: "cube")!,
                        UIImage(named: "cone")!,
                        UIImage(named: "cylinder")!,
                        UIImage(named: "squarePyramid")!
                    ]

        let pngPath = Bundle.main.path(forResource: "grundkörper", ofType: "png")
        print(pngPath)
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print (gkArray.count)
        return gkArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! ImageCollectionViewCell
            
            cell.gkImage.image = gkArray[indexPath.row]
        
            //cell.gkLabel.text = gkArray[indexPath.row].
        
        return cell
        
    }
    
}
