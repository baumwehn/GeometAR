//
//  InputViewController.swift
//  GeometAR
//
//  Created by Birnbaum on 27.04.18.
//  Copyright © 2018 IDMI. All rights reserved.
//

import UIKit


class InputViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var goArray: [GeoObject]?
    var transferGeoObject: GeoObject?
    var arVC: ViewController?
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var blurViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sitView: UIView!
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        blurView.layer.cornerRadius = 20
        blurView.layer.masksToBounds = true
        blurView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        // Passe die Höhe der BlurView an den Inhalt an:
        blurViewHeightConstraint.constant = collectionView.frame.height + sitView.frame.height + dismissButton.frame.height + 50
    }
    
    @IBAction func dice(_ sender: Any) {
        arVC?.qrButtonAction(arVC!)
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print (goArray!.count)
        return goArray!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! ImageCollectionViewCell
            
        cell.gkImage.image = goArray![indexPath.row].displayImage
        cell.gkLabel.text = goArray![indexPath.row].displayName
        
        return cell
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        transferGeoObject = goArray![indexPath.row]
        print (indexPath.row)
        print (transferGeoObject!.displayName)
        performSegue(withIdentifier: "objectSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ObjectInputViewController {
            destination.nGeoObject = transferGeoObject
            destination.arVC = self.arVC
            destination.ipVC = self
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true, completion: nil)
    }

    
}
