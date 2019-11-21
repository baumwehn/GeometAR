//
//  ObjectInputViewController.swift
//  GeometAR
//
//  Created by Birnbaum on 16.05.18.
//  Copyright © 2018 IDMI. All rights reserved.

import UIKit
import SceneKit
import ARKit

class ObjectInputViewController: UIViewController, UITextFieldDelegate {
    
    var nGeoObject: GeoObject?
    let objectSVHeightOriginal:CGFloat = 320.00
    var objectSrollViewHeight: CGFloat?
    var position: SCNVector3?
    var arVC: ViewController?
    var ipVC: InputViewController?
    let blurEffectViewTag = 100
    var edit: Bool?
    
    @IBOutlet weak var objectScrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var objectSVBottom: NSLayoutConstraint!
    @IBOutlet weak var hinzuButtonPos: NSLayoutConstraint!
    @IBOutlet weak var buttonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var objectTitle: UILabel!
//    @IBOutlet weak var objectBlurView: UIVisualEffectView!
    @IBOutlet weak var objectScrollView: UIScrollView!
    @IBOutlet weak var inputX1: UITextField!
    @IBOutlet weak var inputY1: UITextField!
    @IBOutlet weak var inputZ1: UITextField!
    @IBOutlet weak var inputR1: UITextField!
    @IBOutlet weak var inputX2: UITextField!
    @IBOutlet weak var inputY2: UITextField!
    @IBOutlet weak var inputZ2: UITextField!
    @IBOutlet weak var inputR2: UITextField!
    // Eingabe-Views Outlets
    @IBOutlet weak var hinzuButton: UIButton!
    @IBOutlet weak var xyz1View: UIView!
    @IBOutlet weak var xyz2View: UIView!
    @IBOutlet weak var xyz3View: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var r1View: UIView!
    @IBOutlet weak var r2View: UIView!
    // Labeloutlets
    @IBOutlet weak var zentrum1Label: UILabel!
    @IBOutlet weak var r1Label: UILabel!
    @IBOutlet weak var r2Label: UILabel!
    @IBOutlet weak var xyz1Label: UILabel!
    @IBOutlet weak var xyz2Label: UILabel!
    @IBOutlet weak var xyz3Label: UILabel!
    @IBOutlet weak var langeLabel: UILabel!
    @IBOutlet weak var breiteLabel: UILabel!
    @IBOutlet weak var hoheLabel: UILabel!
    @IBOutlet weak var inputX2Label: UILabel!
    @IBOutlet weak var inputY2Label: UILabel!
    @IBOutlet weak var inputZ2Label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonView.layer.borderWidth = 1
        buttonView.layer.cornerRadius = 10
        buttonView.layer.masksToBounds = true
        
        blurView.layer.cornerRadius = 20
        blurView.layer.masksToBounds = true
        blurView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        objectScrollView.layer.cornerRadius = 20
        objectScrollView.layer.masksToBounds = true
        objectScrollView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        objectTitle.text = "Daten für " + (nGeoObject?.displayName)! + " eingeben"
        hinzuButton.setTitle( nGeoObject!.displayName + " hinzufügen", for: .normal)
        
        // Notifications für die Tastatur:
            NotificationCenter.default.addObserver(self, selector: #selector (keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector (keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Textfelder initialisieren
        inputX1.tintColor = .white
        inputY1.tintColor = .white
        inputZ1.tintColor = .white
        inputR1.tintColor = .white
        inputX2.tintColor = .white
        inputY2.tintColor = .white
        inputZ2.tintColor = .white
        inputR2.tintColor = .white
        inputX1.tag = 1
        inputY1.tag = 2
        inputZ1.tag = 3
        inputR1.tag = 4
        inputX2.tag = 5
        inputY2.tag = 6
        inputZ2.tag = 7
        inputR2.tag = 8
        
        print (edit)
        
        if edit == true{
            print ("in if weg")
            xyz1View.isHidden = false
            r1View.isHidden = false
            xyz2View.isHidden = true
            r2View.isHidden = true
            print (nGeoObject!)
            print (nGeoObject!.position.x)
            let nf = NumberFormatter()
            nf.minimumFractionDigits = 2
            let x = nGeoObject!.position.x * 10.0
            let y = nGeoObject!.position.y * 10.0
            let z = nGeoObject!.position.z * -10.0
            let sphere = nGeoObject!.geometry as! SCNSphere
            print (sphere.radius)
            print( nGeoObject!.geometry)
            
            inputX1.text = nf.string(from:  x as NSNumber)
            inputY1.text = nf.string(from: z as NSNumber)
            inputZ1.text = nf.string(from: y as NSNumber)
            
            
            
        }
        
        else {
            print ("in else weg")
            switch nGeoObject?.modelName {
            case "sphere":
                xyz1View.isHidden = false
                r1View.isHidden = false
                xyz2View.isHidden = true
                r2View.isHidden = true
                //            xyz3View.isHidden = true
                inputR1.text = "0,1"
            case "cube":
                xyz1View.isHidden = false
                zentrum1Label.text = "Ursprung"
                r1View.isHidden = false
                xyz2View.isHidden = true
                r2View.isHidden = true
                //            xyz3View.isHidden = true
                r1Label.text = "Kantenlänge:"
                inputR1.text = "1,0"
            case "cylinder":
                xyz1View.isHidden = false
                xyz1Label.text = "Anfang:"
                r1View.isHidden = false
                inputR1.text = "0,5"
                xyz2View.isHidden = false
                xyz2Label.text = "Ende:"
                inputX2.text = "0,0"
                inputY2.text = "0,0"
                inputZ2.text = "2,0"
                r2View.isHidden = true
            //            xyz3View.isHidden = true
            case "quader":
                xyz1View.isHidden = false
                xyz1Label.text = "Ecke A:"
                r1View.isHidden = true
                xyz2View.isHidden = false
                xyz2Label.text = "Ecke B:"
                r2View.isHidden = true
                inputX2.text = "3,0"
                inputY2.text = "2,0"
                inputZ2.text = "1,0"
            //            xyz3View.isHidden = true
            case "cone":
                xyz1View.isHidden = false
                xyz1Label.text = "Zentrum"
                r1View.isHidden = false
                r1Label.text = "Radius Unten:"
                inputR1.text = "2,0"
                xyz2View.isHidden = false
                xyz2Label.text = "Höhe"
                inputX2Label.text = "H:"
                inputX2.text = "2,0"
                inputY2.isHidden = true
                inputZ2.isHidden = true
                inputY2Label.isHidden = true
                inputZ2Label.isHidden = true
                r2View.isHidden = true
                //            r2Label.text = "Radius Oben:"
                //            inputR2.text = "0.0"
            //            xyz3View.isHidden = true
            case "pyramid":
                xyz1View.isHidden = false
                r1View.isHidden = true
                xyz2View.isHidden = false
                xyz2Label.text = "Maße"
                r2View.isHidden = true
                //            xyz3View.isHidden = true
                breiteLabel.text = "B:"
                langeLabel.text = "L:"
                hoheLabel.text = "H:"
                inputX2.text = "2,0"
                inputY2.text = "2,0"
                inputZ2.text = "3,0"
            default:
                xyz1View.isHidden = false
                xyz2View.isHidden = false
                //           xyz3View.isHidden = false
                r1View.isHidden = false
                r2View.isHidden = false
                

            }
            inputX1.text = "1,0"
            inputY1.text = "1,0"
            inputZ1.text = "1,0"
        }
        
        objectSrollViewHeight = calcHeight()
        hinzuButtonPos.constant = calcHeight() - 90
        

        inputX1.clearsOnBeginEditing = false;
        inputX1.becomeFirstResponder()
    }
    
    
    // Methoden
    @IBAction func dismiss(_ sender: Any) {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // Erzeugt ein neues Objekt und fügt es zum Ursprung hinzu
    @IBAction func addObjectButton(_ sender: Any) {
        // z und y werden aufgrund des deutschen Systems vertauscht
        let x1 = self.bruchBerechnen(uString: inputX1.text!) * 0.1
        let z1 = self.bruchBerechnen(uString: inputY1.text!) * 0.1 * -1
        let y1 = self.bruchBerechnen(uString: inputZ1.text!) * 0.1
        var r1 = self.bruchBerechnen(uString: inputR1.text!) * 0.1
        let x2 = self.bruchBerechnen(uString: inputX2.text!) * 0.1
        let z2 = self.bruchBerechnen(uString: inputY1.text!) * 0.1 * -1
        let y2  = self.bruchBerechnen(uString: inputZ2.text!) * 0.1
        let r2 = self.bruchBerechnen(uString: inputR2.text!) * 0.1

       
        position = SCNVector3(x1,y1,z1)
        let newObject = GeoObject(modelName: (nGeoObject?.modelName)!, displayName: (nGeoObject?.displayName)!, displayImage: (nGeoObject?.displayImage)!)
        
        newObject.opacity = 0.85
        newObject.geometry?.firstMaterial?.isDoubleSided = true
        
        switch nGeoObject?.modelName {
        case "sphere":
            print (r1)
            if(r1<0.0025) {r1 = 0.0025}
            newObject.position = position!
            newObject.geometry = SCNSphere(radius: CGFloat(r1))
            newObject.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        case "cube":
            newObject.position = SCNVector3(x1+(0.5*r1), y1+(0.5*r1), z1+(-0.5*r1) )
            newObject.geometry = SCNBox (width: CGFloat(r1), height: CGFloat(r1), length: CGFloat(r1), chamferRadius: 0)
            newObject.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        case "cylinder":
            arVC?.ursprung.addChildNode((arVC?.erstelleStrecke(punkt1: SCNVector3(x1, y1, z1), punkt2: SCNVector3(x2, y2, z2), radius: r1))!)
            dismiss(animated: true, completion: nil)
            return;
        case "quader":
            newObject.position = SCNVector3(x1+(0.5*abs(x1-x2)), y1+(0.5*abs(y1-y2)), z1+(-0.5*abs(z1-z2)) )
            newObject.geometry = SCNBox (width: CGFloat(abs(x1-x2)), height: CGFloat(abs(y1-y2)), length: CGFloat(abs(z1-z2) ), chamferRadius: 0)
            newObject.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        case "cone":
            // Input von Kegel:
            newObject.position = SCNVector3(x1, y1+(0.5*x2), z1 )
            newObject.geometry = SCNCone(topRadius: CGFloat(r2), bottomRadius: CGFloat(r1), height: CGFloat(x2))
            newObject.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            print("Kegel erzeugt")
        case "pyramid":
            newObject.position = position!
            newObject.geometry = SCNPyramid(width: CGFloat(x2), height: CGFloat(y2), length: CGFloat(z2))
            newObject.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
        default:
            arVC?.sessionInfoLabel.text = "Fehler aufgetreten. Kein Objekt hinzugefügt"
        }
        arVC?.ursprung.addChildNode(newObject)
        view.endEditing(true)
        arVC?.sessionInfoLabel.text = (newObject.displayName) + " hinzugefügt"
        dismiss(animated: false, completion: nil)
        ipVC?.dismiss(animated: true, completion: nil)
    }
    
    func bruchBerechnen(uString: String) -> Float{
        if (uString.contains("/")){
            let index = uString.firstIndex(of: "/")
            let factor1 = uString.prefix(upTo: index!) as NSString
            let factor2 = uString.suffix(from: index!).dropFirst() as NSString
            let result = factor1.floatValue / factor2.floatValue
            return result
        }
        else {return (uString as NSString).floatValue }
    }
    
    
    // Berechnet die Gesamthöhe der angezeigten Views
    private func calcHeight() -> CGFloat {
        var gesHeight = objectTitle.frame.height  + buttonView.frame.height + 60
        if(!xyz1View.isHidden){
            gesHeight += xyz1View.frame.height
        }
        if(!xyz2View.isHidden){
            gesHeight += xyz2View.frame.height
        }
        
        if(!r1View.isHidden){
            gesHeight += r1View.frame.height
        }
        if(!r2View.isHidden){
            gesHeight += r2View.frame.height
        }
        return gesHeight
    }
    
    
    // Drehen des Geräts bei geöffnetem Menü
    //__________________________________________________________________________________
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)

    }
    
    @objc func deviceRotated(){
        if UIDevice.current.orientation.isLandscape {
            print("landscape")

        }
        if UIDevice.current.orientation.isPortrait {
           self.objectSVBottom.constant = 0
        }
    }
    
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    // KEYBOARD Einstellungen
    //__________________________________________________________________________________
    @objc func keyboardWillShow(notification: NSNotification){
        if let userInfo = notification.userInfo {
            let rect:CGRect = userInfo["UIKeyboardFrameEndUserInfoKey"] as! CGRect
         
            // Höhenverschiebung bestimmen
            var zielY = rect.height + self.objectSrollViewHeight!
            // Entscheidung, ob die Gesamthöhe größer ist als der Screen
            if(zielY > UIScreen.main.bounds.height){
                objectSVBottom.constant = rect.height
                zielY = UIScreen.main.bounds.height - rect.height
            }
            else {
                zielY = rect.height + self.objectSrollViewHeight!
            }
            
            
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.2, animations: {
                self.objectScrollViewHeightConstraint.constant = zielY
                self.view.layoutIfNeeded()
                })
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        self.objectScrollViewHeightConstraint.constant = self.objectSrollViewHeight!
        self.view.layoutIfNeeded()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
 
    // Touch-Einstellungen
    //__________________________________________________________________________________
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches began")
        inputX1.resignFirstResponder()
        inputY1.resignFirstResponder()
        inputZ1.resignFirstResponder()
        
        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.objectScrollViewHeightConstraint.constant = self.objectSrollViewHeight!
            self.objectSVBottom.constant = 0
            self.view.layoutIfNeeded()
        })
        
        view.endEditing(true)
    }

    // Hilfsmethoden
    
    private func bestimmeGeradenmittelpunkt(a: SCNVector3, b: SCNVector3) -> SCNVector3 {
        var mittelpunkt = SCNVector3()
        mittelpunkt.x = (a.x+b.x)/2
        mittelpunkt.y = (a.y+b.y)/2
        mittelpunkt.z = (a.z+b.z)/2
        return mittelpunkt
    }
    
    func blurBackground() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.objectScrollView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = blurEffectViewTag
        self.objectScrollView.addSubview(blurEffectView)
        blurEffectView.sendSubviewToBack(objectScrollView)
    }
  
    

}
