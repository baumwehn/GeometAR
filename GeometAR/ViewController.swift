//
//  ViewController.swift
//  GeometrieAR
//
//  Created by Birnbaum on 21.02.18.
//  Copyright © 2018 IDMI. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {


    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var hilfeNr: UILabel!
    @IBOutlet weak var pfeilLinks: UIButton!
    @IBOutlet weak var pfeilRechts: UIButton!
    @IBOutlet weak var sessionInfoFX: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var configuration = ARWorldTrackingConfiguration()
    var koordGesetzt = false
    var ursprung = SCNNode()
    let schriftgroesse = 0.003
    var hilfeschritt: Int = 0
    var objekte = [SCNNode()]
    var focusSquare = FocusSquare()
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    var receivedObject: GeoObject?
    var dragOnInfinitePlanesEnabled = false
    var availableGeoKoerper = [GeoObject]()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [] //ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin
        self.sceneView.session.run(configuration)
        self.configuration.planeDetection = .horizontal
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        if (!koordGesetzt) {
            pfeilLinks.isHidden = true
            pfeilRechts.isHidden = true
            qrButton.isHidden = true
            addButton.isHidden = true
            
            sessionInfoFX.layer.cornerRadius = 10
            sessionInfoFX.layer.masksToBounds = true
            
            setupFocusSquare()
            setupAvailableGeoKoerper()
            // Tap Recognizer
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapGesture))
            view.addGestureRecognizer(tapGestureRecognizer)
            
            sessionInfoLabel.text = "Bildschirm berühren um KO-System zu platzieren"
        }
    }
    
    private func myPlane(){
        //////////////////////////////////////////////////////////////////////////////
        // Ebene testweie hinzufügen:
        let planeNode = SCNNode()
        planeNode.geometry = SCNPlane(width: CGFloat(0.4), height: CGFloat(0.4))
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        planeNode.opacity = 0.75
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = SCNVector3(0, 0.1, 0)
        planeNode.eulerAngles = SCNVector3(25.degreesToRadians, 62.degreesToRadians, 0 )
        //            anfangEbene.eulerAngles = SCNVector3(0, 90.degreesToRadians, -90.degreesToRadians + ebeneWinkel.degreesToRadians )
        ursprung.addChildNode(planeNode)
        
        let e1text = SCNText(string: "E1", extrusionDepth: 1)
        let e1node = SCNNode(geometry: e1text)
        e1node.position = SCNVector3(0.05 , 0.05, -0.1)
        //e1node.eulerAngles.y = -.pi/2
        e1node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        e1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprung.addChildNode(e1node)
        
        //Punkt:
        let punkt = SCNNode()
        punkt.geometry = SCNSphere(radius: CGFloat(0.005))
        punkt.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        punkt.position = SCNVector3(0.3, 0.2, -0.01)
        ursprung.addChildNode(punkt)
        //Beschriftung Punkt
        let a1text = SCNText(string: "A", extrusionDepth: 1)
        let a1node = SCNNode(geometry: a1text)
        a1node.position = SCNVector3(0.28 , 0.18, -0.01)
        //e1node.eulerAngles.y = -.pi/2
        a1node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        a1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprung.addChildNode(a1node)

    }
    override func viewDidAppear(_ animated: Bool) {
        UserDefaults.standard.set(koordGesetzt, forKey: "koordGesetzt")
    }
    
    private func setupAvailableGeoKoerper(){
        let sphere = GeoObject(modelName: "sphere", displayName: "Kugel", displayImage: #imageLiteral(resourceName: "sphere"))
        sphere.geometry = SCNSphere()
        availableGeoKoerper.append(sphere)
        let cone = GeoObject(modelName: "cone", displayName: "Kegel", displayImage: #imageLiteral(resourceName: "cone"))
        cone.geometry = SCNCone()
        availableGeoKoerper.append(cone)
        let cube = GeoObject(modelName: "cube", displayName: "Würfel", displayImage: #imageLiteral(resourceName: "cube"))
        cube.geometry = SCNBox()
        availableGeoKoerper.append(cube)
        let cylinder = GeoObject(modelName: "cylinder", displayName: "Zylinder", displayImage: #imageLiteral(resourceName: "cylinder"))
        cube.geometry = SCNCylinder()
        availableGeoKoerper.append(cylinder)
        let quader  = GeoObject(modelName: "quader", displayName: "Quader", displayImage: #imageLiteral(resourceName: "quader"))
        quader.geometry = SCNBox()
        availableGeoKoerper.append(quader)
        let pyramid = GeoObject(modelName: "pyramid", displayName: "Pyramide", displayImage: #imageLiteral(resourceName: "squarePyramid"))
        pyramid.geometry = SCNPyramid()
        availableGeoKoerper.append(pyramid)
    }
    
    @IBAction func resetSession(_ sender: Any) {
        resetTracking()
        
    }
   
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tempInputViewController = segue.destination as? InputViewController{
            tempInputViewController.goArray = availableGeoKoerper
            tempInputViewController.arVC = self
        }
        
        if let tempInputViewController2 = segue.destination as? ObjectInputViewController{
            tempInputViewController2.nGeoObject = receivedObject
            tempInputViewController2.arVC = self
            tempInputViewController2.edit = true
        }
    }
 
    @objc func handleTapGesture(sender: UITapGestureRecognizer) {
        if koordGesetzt == true {
                let location: CGPoint = sender.location(in: sceneView)
                let hits = self.sceneView.hitTest(location, options: nil)
                if !hits.isEmpty {
                    let tappedNode = hits.first?.node
                    receivedObject = tappedNode as? GeoObject
                    self.performSegue(withIdentifier: "editSegue", sender: self)
                }
        }
        
        else {
            let planeHitTestResults = sceneView.hitTest(view.center, types: .existingPlaneUsingExtent)
            
            if let result = planeHitTestResults.first {
                let hitPosition = SCNVector3.positionFromTransform(result.worldTransform)
                ursprung.position = hitPosition
                ursprung.position.x -= 0.1
                ursprung.eulerAngles.y = (sceneView.session.currentFrame?.camera.eulerAngles.y)!
                sceneView.scene.rootNode.addChildNode(ursprung)
                setzeKoord()
                koordGesetzt = true
                sessionInfoLabel.text = "KO-System platziert\nObjekte über + hinzufügen"
                focusSquare.hide()
            }
            else {
                ursprung.position = focusSquare.position
                ursprung.position.x -= 0.1
                ursprung.eulerAngles.y = (sceneView.session.currentFrame?.camera.eulerAngles.y)!
                sceneView.scene.rootNode.addChildNode(ursprung)
                setzeKoord()
                koordGesetzt = true
                sessionInfoLabel.text = "KO-System gesetzt\nObjekte über + hinzufügen"
                focusSquare.hide()
            }
            
            addButton.isHidden = false
        }
        self.myPlane()
    }
    
    @IBAction func qrButtonAction(_ sender: Any) {
        if (koordGesetzt == true && hilfeschritt == 0) {
            objekte.removeAll()
            hilfeschritt = 0
            print(hilfeschritt)
        
            objekte.append(erstelleWuerfel(startpunkt: SCNVector3(0,0,0), nkante: 3) )
            objekte.append(erstelleEbene(startpunkt: SCNVector3(0,0,0), nkanteX: 3, nkanteY:  ((1.5*1.5) + (3*3)).squareRoot() ))
            objekte.append(erstelleStrecke(punkt1: SCNVector3(0,0.3,-0.3) , punkt2: SCNVector3(0.3,0,0), radius: 0.001))
            objekte.append(erstellePunkt(koord: SCNVector3((4/3)*0.15, (2/3)*0.15, (2/3)*(-0.15)), radiusP: 0.004))
            ursprung.addChildNode( objekte[0] )
            hilfeschritt += 1
            hilfeNr.text = ("\(hilfeschritt) / \(objekte.count)")
            pfeilLinks.isHidden = false
            pfeilRechts.isHidden = false
            hilfeNr.isHidden = false
        }
        
        else {
            return
        }
        
    }
    
     @IBAction func pfeilLinksButton(_ sender: Any) {
        print (hilfeschritt)
        if hilfeschritt>=1 {
            hilfeschritt -= 1
            objekte[hilfeschritt].removeFromParentNode()
            hilfeNr.text = ("\(hilfeschritt)" + " / " + "\(objekte.count)")
        }
        else {
            self.sessionInfoLabel.text = "Nicht möglich"
            print(hilfeschritt)
        }
    }
    
    @IBAction func pfeilRechtsButton(_ sender: Any) {
        print (hilfeschritt)
        if (hilfeschritt<objekte.count){
            ursprung.addChildNode(objekte[hilfeschritt])
            hilfeschritt += 1
            hilfeNr.text = ("\(hilfeschritt) / \(objekte.count)")
        }
        else {
            self.sessionInfoLabel.text = "Kein Hilfeschritt mehr übrig"
            print(hilfeschritt)
        }
    }
    

    
   
    
    public func erstellePunkt (koord: SCNVector3, radiusP: Float) -> SCNNode {
        if koordGesetzt == true {
            let punkt = SCNNode()
            punkt.geometry = SCNSphere(radius: CGFloat(radiusP))
            punkt.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            punkt.position = koord
            return punkt
        }
        else {return ursprung}
    }
    
    public func erstelleStrecke (punkt1: SCNVector3, punkt2: SCNVector3, radius: Float)  -> SCNNode {
      
            let abstand = punkt1.distance(receiver: punkt2)
            
            
            // Beide Punkte erstellen
            let punkt1Node = SCNNode()
            punkt1Node.position = punkt1
            let punkt2Node = SCNNode()
            punkt2Node.position = punkt2
            
            //
            punkt1Node.addChildNode(punkt2Node)
            
            // Zylinder erstellen
            let zylinder = SCNCylinder(radius: CGFloat(radius), height: CGFloat(abstand))
            zylinder.firstMaterial?.diffuse.contents = UIColor.orange
            
            // Mittelpunkt erstellen, bestimmen und zeichnen
            let mittelpunkt = SCNNode()
            mittelpunkt.position = bestimmeGeradenmittelpunkt(a: punkt1, b: punkt2)
            // Zusätzlicher Punkt, um den senkrechten Zylinder in die Waagerechte zu bringen
            let nodeCyl = SCNNode(geometry: zylinder )
            nodeCyl.eulerAngles.x = -.pi / 2
            nodeCyl.opacity = 0.85
            mittelpunkt.look(at: punkt2)
            
            // Alle Knoten hinzufügen
            
            mittelpunkt.addChildNode(nodeCyl)
            
            return mittelpunkt
    
    }
    
    private func erstelleEbene(startpunkt: SCNVector3, nkanteX: Float, nkanteY: Float) -> SCNNode {
        if koordGesetzt == true {
            let anfangEbene = SCNNode()
            let ebeneWinkel = 26.565
            anfangEbene.position = startpunkt
            
            let kanteX = nkanteX/10
            let kanteY = nkanteY/10
            
            let planeNode = SCNNode()
            planeNode.geometry = SCNPlane(width: CGFloat(kanteX), height: CGFloat(kanteY))
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
            planeNode.opacity = 0.75
            planeNode.geometry?.firstMaterial?.isDoubleSided = true
            planeNode.position = SCNVector3(kanteX/2, kanteY/2, 0)
            anfangEbene.eulerAngles = SCNVector3(0, 90.degreesToRadians, -90.degreesToRadians + ebeneWinkel.degreesToRadians )
            anfangEbene.addChildNode(planeNode)
            return anfangEbene
        }
        else {return ursprung}
    }
    
    private func setzeSkalierung() -> SCNNode{
        let ursprungSkalierung = SCNNode()
        let ringradius = CGFloat(0.0025)
        let piperadius = CGFloat(0.001)
        
        // X-Achsen-Skalierung
        let x1 = SCNNode()
        x1.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        x1.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x1.position = SCNVector3(0.1, 0, 0)
        x1.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(x1)
        let x1text = SCNText(string: "1", extrusionDepth: 1)
        let x1node = SCNNode(geometry: x1text)
        x1node.position = SCNVector3(0.095 , 0.0, 0.03)
        x1node.eulerAngles.x = -.pi/2
        x1node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(x1node)
        
        let x2 = SCNNode()
        x2.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        x2.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x2.position = SCNVector3(0.2, 0, 0)
        x2.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(x2)
        let x2text = SCNText(string: "2", extrusionDepth: 1)
        let x2node = SCNNode(geometry: x2text)
        x2node.position = SCNVector3(0.195 , 0.0, 0.03)
        x2node.eulerAngles.x = -.pi/2
        x2node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x2node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(x2node)
        
        let x3 = SCNNode()
        x3.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        x3.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x3.position = SCNVector3(0.3, 0, 0)
        x3.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(x3)
        let x3text = SCNText(string: "3", extrusionDepth: 1)
        let x3node = SCNNode(geometry: x3text)
        x3node.position = SCNVector3(0.295 , 0.0, 0.03)
        x3node.eulerAngles.x = -.pi/2
        x3node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x3node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(x3node)
        
        let x4 = SCNNode()
        x4.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        x4.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x4.position = SCNVector3(0.4, 0, 0)
        x4.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(x4)
        let x4text = SCNText(string: "4", extrusionDepth: 1)
        let x4node = SCNNode(geometry: x4text)
        x4node.position = SCNVector3(0.395 , 0.0, 0.03)
        x4node.eulerAngles.x = -.pi/2
        x4node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x4node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(x4node)
        
        let x5 = SCNNode()
        x5.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        x5.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x5.position = SCNVector3(0.5, 0, 0)
        x5.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(x5)
        let x5text = SCNText(string: "5", extrusionDepth: 1)
        let x5node = SCNNode(geometry: x5text)
        x5node.position = SCNVector3(0.495 , 0.0, 0.03)
        x5node.eulerAngles.x = -.pi/2
        x5node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        x5node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(x5node)
        
        let mx1 = SCNNode()
        mx1.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        mx1.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx1.position = SCNVector3(-0.1, 0, 0)
        mx1.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(mx1)
        let mx1text = SCNText(string: "-1", extrusionDepth: 1)
        mx1text.alignmentMode = convertFromCATextLayerAlignmentMode(CATextLayerAlignmentMode.center)
        let mx1node = SCNNode(geometry: mx1text)
        mx1node.position = SCNVector3(-0.11 , 0.0, 0.03)
        mx1node.eulerAngles.x = -.pi/2
        mx1node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(mx1node)
        
        let mx2 = SCNNode()
        mx2.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        mx2.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx2.position = SCNVector3(-0.2, 0, 0)
        mx2.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(mx2)
        let mx2text = SCNText(string: "-2", extrusionDepth: 1)
        let mx2node = SCNNode(geometry: mx2text)
        mx2node.position = SCNVector3(-0.21 , 0.0, 0.03)
        mx2node.eulerAngles.x = -.pi/2
        mx2node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx2node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(mx2node)
        
        let mx3 = SCNNode()
        mx3.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        mx3.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx3.position = SCNVector3(-0.3, 0, 0)
        mx3.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(mx3)
        let mx3text = SCNText(string: "-3", extrusionDepth: 1)
        let mx3node = SCNNode(geometry: mx3text)
        mx3node.position = SCNVector3(-0.31 , 0.0, 0.03)
        mx3node.eulerAngles.x = -.pi/2
        mx3node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx3node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(mx3node)
        
        let mx4 = SCNNode()
        mx4.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        mx4.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx4.position = SCNVector3(-0.4, 0, 0)
        mx4.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(mx4)
        let mx4text = SCNText(string: "-4", extrusionDepth: 1)
        let mx4node = SCNNode(geometry: mx4text)
        mx4node.position = SCNVector3(-0.41 , 0.0, 0.03)
        mx4node.eulerAngles.x = -.pi/2
        mx4node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx4node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(mx4node)
        
        let mx5 = SCNNode()
        mx5.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        mx5.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx5.position = SCNVector3(-0.5, 0, 0)
        mx5.eulerAngles.z = -.pi/2
        ursprungSkalierung.addChildNode(mx5)
        let mx5text = SCNText(string: "-5", extrusionDepth: 1)
        let mx5node = SCNNode(geometry: mx5text)
        mx5node.position = SCNVector3(-0.51 , 0.0, 0.03)
        mx5node.eulerAngles.x = -.pi/2
        mx5node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        mx5node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(mx5node)
        
        
        // Y-Achsen-Skalierung
        let y1 = SCNNode()
        y1.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        y1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y1.position = SCNVector3(0.0, 0, -0.1)
        y1.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(y1)
        let y1text = SCNText(string: "1", extrusionDepth: 1)
        let y1node = SCNNode(geometry: y1text)
        y1node.position = SCNVector3(-0.015 , 0.0, -0.09)
        y1node.eulerAngles.x = -.pi/2
        y1node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(y1node)
        
        let y2 = SCNNode()
        y2.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        y2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y2.position = SCNVector3(0.0, 0, -0.2)
        y2.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(y2)
        let y2text = SCNText(string: "2", extrusionDepth: 1)
        let y2node = SCNNode(geometry: y2text)
        y2node.position = SCNVector3(-0.015 , 0.0, -0.19)
        y2node.eulerAngles.x = -.pi/2
        y2node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y2node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(y2node)
        
        let y3 = SCNNode()
        y3.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        y3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y3.position = SCNVector3(0.0, 0, -0.3)
        y3.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(y3)
        let y3text = SCNText(string: "3", extrusionDepth: 1)
        let y3node = SCNNode(geometry: y3text)
        y3node.position = SCNVector3(-0.015 , 0.0, -0.29)
        y3node.eulerAngles.x = -.pi/2
        y3node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y3node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(y3node)
        
        let y4 = SCNNode()
        y4.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        y4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y4.position = SCNVector3(0.0, 0, -0.4)
        y4.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(y4)
        let y4text = SCNText(string: "4", extrusionDepth: 1)
        let y4node = SCNNode(geometry: y4text)
        y4node.position = SCNVector3(-0.015 , 0.0, -0.39)
        y4node.eulerAngles.x = -.pi/2
        y4node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y4node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(y4node)
        
        let y5 = SCNNode()
        y5.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        y5.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y5.position = SCNVector3(0.0, 0, -0.1)
        y5.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(y5)
        let y5text = SCNText(string: "5", extrusionDepth: 1)
        let y5node = SCNNode(geometry: y5text)
        y5node.position = SCNVector3(-0.015 , 0.0, -0.49)
        y5node.eulerAngles.x = -.pi/2
        y5node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        y5node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(y5node)
        
        let my1 = SCNNode()
        my1.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        my1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my1.position = SCNVector3(0.0, 0, 0.1)
        my1.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(my1)
        let my1text = SCNText(string: "-1", extrusionDepth: 1)
        let my1node = SCNNode(geometry: my1text)
        my1node.position = SCNVector3(-0.025 , 0.0, 0.11)
        my1node.eulerAngles.x = -.pi/2
        my1node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(my1node)
        
        let my2 = SCNNode()
        my2.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        my2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my2.position = SCNVector3(0.0, 0, 0.2)
        my2.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(my2)
        let my2text = SCNText(string: "-2", extrusionDepth: 1)
        let my2node = SCNNode(geometry: my2text)
        my2node.position = SCNVector3(-0.025 , 0.0, 0.21)
        my2node.eulerAngles.x = -.pi/2
        my2node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my2node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(my2node)
        
        let my3 = SCNNode()
        my3.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        my3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my3.position = SCNVector3(0.0, 0, 0.3)
        my3.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(my3)
        let my3text = SCNText(string: "-3", extrusionDepth: 1)
        let my3node = SCNNode(geometry: my3text)
        my3node.position = SCNVector3(-0.025 , 0.0, 0.31)
        my3node.eulerAngles.x = -.pi/2
        my3node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my3node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(my3node)
        
        let my4 = SCNNode()
        my4.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        my4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my4.position = SCNVector3(0.0, 0, 0.4)
        my4.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(my4)
        let my4text = SCNText(string: "-4", extrusionDepth: 1)
        let my4node = SCNNode(geometry: my4text)
        my4node.position = SCNVector3(-0.025 , 0.0, 0.41)
        my4node.eulerAngles.x = -.pi/2
        my4node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my4node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(my4node)
        
        let my5 = SCNNode()
        my5.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        my5.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my5.position = SCNVector3(0.0, 0, 0.5)
        my5.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(my5)
        let my5text = SCNText(string: "-5", extrusionDepth: 1)
        let my5node = SCNNode(geometry: my5text)
        my5node.position = SCNVector3(-0.025 , 0.0, 0.51)
        my5node.eulerAngles.x = -.pi/2
        my5node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        my5node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(my5node)
        
        // Z-Achsen-Skalierung
        let z1 = SCNNode()
        z1.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        z1.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z1.position = SCNVector3(0.0, 0.1, 0)
        // z1.eulerAngles.x = -.pi/2
        ursprungSkalierung.addChildNode(z1)
        let z1text = SCNText(string: "1", extrusionDepth: 1)
        let z1node = SCNNode(geometry: z1text)
        z1node.position = SCNVector3(-0.015 , 0.09, 0)
        // z1node.eulerAngles.x = -.pi/2
        z1node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z1node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(z1node)
        
        let z2 = SCNNode()
        z2.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        z2.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z2.position = SCNVector3(0.0, 0.2, 0)
        ursprungSkalierung.addChildNode(z2)
        let z2text = SCNText(string: "2", extrusionDepth: 1)
        let z2node = SCNNode(geometry: z2text)
        z2node.position = SCNVector3(-0.015 , 0.19, 0)
        z2node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z2node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(z2node)
        
        let z3 = SCNNode()
        z3.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        z3.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z3.position = SCNVector3(0.0, 0.3, 0)
        ursprungSkalierung.addChildNode(z3)
        let z3text = SCNText(string: "3", extrusionDepth: 1)
        let z3node = SCNNode(geometry: z3text)
        z3node.position = SCNVector3(-0.015 , 0.29, 0)
        z3node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z3node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(z3node)
        
        let z4 = SCNNode()
        z4.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        z4.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z4.position = SCNVector3(0.0, 0.4, 0)
        ursprungSkalierung.addChildNode(z4)
        let z4text = SCNText(string: "4", extrusionDepth: 1)
        let z4node = SCNNode(geometry: z4text)
        z4node.position = SCNVector3(-0.015 , 0.39, 0)
        z4node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z4node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(z4node)
        
        let z5 = SCNNode()
        z5.geometry = SCNTorus(ringRadius: ringradius, pipeRadius: piperadius)
        z5.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z5.position = SCNVector3(0.0, 0.5, 0)
        ursprungSkalierung.addChildNode(z5)
        let z5text = SCNText(string: "5", extrusionDepth: 1)
        let z5node = SCNNode(geometry: z5text)
        z5node.position = SCNVector3(-0.015 , 0.49, 0)
        z5node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        z5node.scale = SCNVector3(schriftgroesse/2, schriftgroesse/2, schriftgroesse/2)
        ursprungSkalierung.addChildNode(z5node)


        
        
        
        return ursprungSkalierung
    }
    
    private func erstelleWuerfel(startpunkt: SCNVector3, nkante: Float) -> SCNNode {
        if koordGesetzt == true {
            let achsenDicke: CGFloat = 0.001
            let kante = nkante/10
            
            // Knoten erstellen, um diesen später noch versetzen zu können
            let anfang = SCNNode()
            anfang.position = startpunkt
            
            // Punkte des Würfels erstellen
            let a = SCNNode()
            a.geometry = SCNSphere(radius: achsenDicke+0.0005)
            a.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            anfang.addChildNode(a)
            
            let b = SCNNode()
            b.geometry = SCNSphere(radius: achsenDicke+0.0005)
            b.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            b.position = SCNVector3(kante, 0, 0)
            anfang.addChildNode(b)
            
            let c = SCNNode()
            c.geometry = SCNSphere(radius: achsenDicke+0.0005)
            c.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            c.position = SCNVector3(kante, 0, -kante)
            anfang.addChildNode(c)
            
            let d = SCNNode()
            d.geometry = SCNSphere(radius: achsenDicke+0.0005)
            d.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            d.position = SCNVector3(0, 0, -kante)
            anfang.addChildNode(d)
            //Ebene 2
            let e = SCNNode()
            e.geometry = SCNSphere(radius: achsenDicke+0.0005)
            e.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            e.position = SCNVector3(0, kante, -kante)
            anfang.addChildNode(e)
            
            let f = SCNNode()
            f.geometry = SCNSphere(radius: achsenDicke+0.0005)
            f.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            f.position = SCNVector3(kante, kante, 0)
            anfang.addChildNode(f)
            
            let g = SCNNode()
            g.geometry = SCNSphere(radius: achsenDicke+0.0005)
            g.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            g.position = SCNVector3(kante, kante, -kante)
            anfang.addChildNode(g)
            
            let h = SCNNode()
            h.geometry = SCNSphere(radius: achsenDicke+0.0005)
            h.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            h.position = SCNVector3(0, kante, -kante)
            anfang.addChildNode(h)
            
            // Rote X-Kanten des Würfels
            let xKante1 = SCNNode()
            xKante1.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            xKante1.eulerAngles.z = -.pi / 2
            xKante1.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            xKante1.position = SCNVector3(kante/2,0,0)
            anfang.addChildNode(xKante1)
            
            let xKante2 = SCNNode()
            xKante2.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            xKante2.eulerAngles.z = -.pi / 2
            xKante2.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            xKante2.position = SCNVector3(kante/2,kante,0)
            anfang.addChildNode(xKante2)
            
            let xKante3 = SCNNode()
            xKante3.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            xKante3.eulerAngles.z = -.pi / 2
            xKante3.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            xKante3.position = SCNVector3(kante/2,kante,-kante)
            anfang.addChildNode(xKante3)
            
            let xKante4 = SCNNode()
            xKante4.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            xKante4.eulerAngles.z = -.pi / 2
            xKante4.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            xKante4.position = SCNVector3(kante/2,0,-kante)
            anfang.addChildNode(xKante4)
            
            // Grüne y-Kanten des Würfels
            let yKante1 = SCNNode()
            yKante1.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            yKante1.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            yKante1.position = SCNVector3(x: 0, y: kante/2, z: 0)
            anfang.addChildNode(yKante1)
            
            let yKante2 = SCNNode()
            yKante2.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            yKante2.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            yKante2.position = SCNVector3(kante, kante/2, 0)
            anfang.addChildNode(yKante2)
            
            let yKante3 = SCNNode()
            yKante3.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            yKante3.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            yKante3.position = SCNVector3(kante, kante/2, -kante)
            anfang.addChildNode(yKante3)
            
            let yKante4 = SCNNode()
            yKante4.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            yKante4.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            yKante4.position = SCNVector3(0, kante/2, -kante)
            anfang.addChildNode(yKante4)
            
            // Blaue z-Kanten des Würfels
            let zKante1 = SCNNode()
            zKante1.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            zKante1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            zKante1.eulerAngles.x = -.pi / 2
            zKante1.orientation.z = anfang.orientation.z
            zKante1.position = SCNVector3(0, 0, (-kante/2))
            anfang.addChildNode(zKante1)
        
            let zKante2 = SCNNode()
            zKante2.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            zKante2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            zKante2.eulerAngles.x = -.pi / 2
            zKante2.orientation.z = anfang.orientation.z
            zKante2.position = SCNVector3(kante, 0, (-kante/2))
            anfang.addChildNode(zKante2)
            
            let zKante3 = SCNNode()
            zKante3.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            zKante3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            zKante3.eulerAngles.x = -.pi / 2
            zKante3.orientation.z = anfang.orientation.z
            zKante3.position = SCNVector3(kante, kante, (-kante/2))
            anfang.addChildNode(zKante3)
            
            let zKante4 = SCNNode()
            zKante4.geometry = SCNCylinder(radius: achsenDicke, height: CGFloat(kante))
            zKante4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            zKante4.eulerAngles.x = -.pi / 2
            zKante4.orientation.z = anfang.orientation.z
            zKante4.position = SCNVector3(0, kante, (-kante/2))
            anfang.addChildNode(zKante4)
            
            return anfang
        }
        else {return ursprung}
    }
    
    private func setzeKoord(){
        if koordGesetzt == false {
            let achsenlaenge: CGFloat = 1.2
            let achsenDicke: CGFloat = 0.002
            // x-Achse: rot
            let xKoord = SCNNode()
            xKoord.geometry = SCNCylinder(radius: achsenDicke, height: achsenlaenge)
            xKoord.eulerAngles.z = -.pi / 2
            xKoord.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            // Pfeil: rot
            let xPfeil = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.01, height: 0.02))
            xPfeil.eulerAngles.z = -.pi/2
            xPfeil.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            xPfeil.position = SCNVector3 (achsenlaenge/2,0,0)
            // Y-Achsenbezeichnung
            let xBezText = SCNText(string: "X", extrusionDepth:1)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red
            xBezText.materials = [material]
            let xBez = SCNNode(geometry: xBezText)
            xBez.scale = SCNVector3(schriftgroesse, schriftgroesse, schriftgroesse)
            xBez.geometry = xBezText
            xBez.position = SCNVector3(achsenlaenge/2, 0.01, 0)
            
            
            let yKoord = SCNNode()
            yKoord.position = SCNVector3(0, achsenlaenge/4, 0)
            yKoord.geometry = SCNCylinder(radius: achsenDicke, height: achsenlaenge/2)
            yKoord.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            let yPfeil = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.01, height: 0.02))
            yPfeil.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            yPfeil.position = SCNVector3(0,achsenlaenge/2,0)
            // Y-Achsenbezeichnung
            let yBezText = SCNText(string: "Z", extrusionDepth:1)
            let ymaterial = SCNMaterial()
            ymaterial.diffuse.contents = UIColor.green
            yBezText.materials = [ymaterial]
            let yBez = SCNNode(geometry: yBezText)
            yBez.scale = SCNVector3(schriftgroesse, schriftgroesse, schriftgroesse)
            yBez.geometry = yBezText
            yBez.position = SCNVector3(0.01,achsenlaenge/2,0)
            
            let zKoord = SCNNode()
            zKoord.geometry = SCNCylinder(radius: achsenDicke, height: achsenlaenge)
            zKoord.eulerAngles.x = -.pi / 2
            zKoord.orientation.z = self.sceneView.scene.rootNode.orientation.z
            zKoord.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            let zPfeil = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.01, height: 0.02))
            zPfeil.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            zPfeil.eulerAngles.x = -.pi/2
            zPfeil.position = SCNVector3(0,0,-achsenlaenge/2)
            // Z-Achsenbezeichnung
            let zBezText = SCNText(string: "Y", extrusionDepth:1)
            let zmaterial = SCNMaterial()
            zmaterial.diffuse.contents = UIColor.blue
            zBezText.materials = [zmaterial]
            let zBez = SCNNode(geometry: zBezText)
            zBez.scale = SCNVector3(schriftgroesse, schriftgroesse, schriftgroesse)
            zBez.geometry = zBezText
            zBez.position = SCNVector3(0.01,0,-achsenlaenge/2)
            

            
            
            
            ursprung.addChildNode(xKoord)
            ursprung.addChildNode(xPfeil)
            ursprung.addChildNode(xBez)
            ursprung.addChildNode(yKoord)
            ursprung.addChildNode(yPfeil)
            ursprung.addChildNode(yBez)
            ursprung.addChildNode(zKoord)
            ursprung.addChildNode(zPfeil)
            ursprung.addChildNode(zBez)
            
            ursprung.addChildNode(setzeSkalierung())
            
            koordGesetzt = true
            print ("koord. gesetzt")
            
        }
    }
  
    // private func setzeText(String: text, x, y, z, farbe)
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if(koordGesetzt == true){
            return
        }
        else {
            sessionInfoLabel.text = "KO-System durch tippen platzieren"
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        return
    }
    

    // MARK: - ARSessionDelegate
    
    
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        sessionInfoLabel.text = "Anker gelöscht"
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(trackingState: camera.trackingState)
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session unterbrochen - Bitte neu starten"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption beendet"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session fehlgeschlagen: \(error.localizedDescription)"
        resetTracking()
    }
    
    // Eigene Methoden
    
    private func updateSessionInfoLabel(trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        if koordGesetzt == false {
            var message = ""
            
            switch trackingState {
                
            case .normal:
                // No feedback needed when tracking is normal and planes are visible.
                message = "Gerät ca. 45° Richtung Untergrund neigen \nund auf Bildschirm tippen"
                
            case .notAvailable:
                message = "Tracking nicht verfügbar."
                
            case .limited(.excessiveMotion):
                message = "Gerät langsamer bewegen"
                
            case .limited(.insufficientFeatures):
                message = "Untergrund suchen, oder Licht verbessern"
                
            case .limited(.initializing):
                message = "Initialisiere AR session"
                
            case .limited(.relocalizing):
                message = "Positioniere ARsession neu"
            }
            
            sessionInfoLabel.text = message
            sessionInfoFX.isHidden = message.isEmpty
        }
    }
    
    private func resetTracking() {
        setupFocusSquare()
        objekte.removeAll()
        ursprung.removeFromParentNode()
        ursprung = SCNNode()
        koordGesetzt = false
        hilfeNr.isHidden = true
        hilfeschritt = 0
        pfeilRechts.isHidden = true
        pfeilLinks.isHidden = true
        self.addButton.isHidden = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sessionInfoLabel.text = "Session zurückgesetzt"
    }
    
    private func bestimmeGeradenmittelpunkt(a: SCNVector3, b: SCNVector3) -> SCNVector3 {
        var mittelpunkt = SCNVector3()
        mittelpunkt.x = (a.x+b.x)/2
        mittelpunkt.y = (a.y+b.y)/2
        mittelpunkt.z = (a.z+b.z)/2
        return mittelpunkt
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }

    func setupFocusSquare() {
        focusSquare.unhide()
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    func updateFocusSquare() {
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(view.center, objectPos: focusSquare.position)
        if let worldPosition = worldPosition {
            focusSquare.update(for: worldPosition, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
    

}
// Wandelt Gradzahl in Radius um
extension Double {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
// Berechnet den Abstand zweier Punkte
private extension SCNVector3{
    func distance(receiver:SCNVector3) -> Float{
        let xd = receiver.x - self.x
        let yd = receiver.y - self.y
        let zd = receiver.z - self.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))

        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}

extension String {
    var kommaZuPunkt: String { return String(self).replacingOccurrences(of: ",", with: ".")}
}

extension ViewController {
    
    // Code from Apple PlacingObjects demo: https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCATextLayerAlignmentMode(_ input: CATextLayerAlignmentMode) -> String {
	return input.rawValue
}
