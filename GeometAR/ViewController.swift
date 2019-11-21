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


    @IBOutlet weak var addZ: UITextField!
    @IBOutlet weak var addY: UITextField!
    @IBOutlet weak var addX: UITextField!
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
    var dragOnInfinitePlanesEnabled = false
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ ] //ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin
        self.sceneView.session.run(configuration)
        self.configuration.planeDetection = .horizontal
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        
        pfeilLinks.isHidden = true
        pfeilRechts.isHidden = true
        

        sessionInfoFX.layer.cornerRadius = 10
        sessionInfoFX.layer.masksToBounds = true
        
        setupFocusSquare()
        // Tap Recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapGesture))
        view.addGestureRecognizer(tapGestureRecognizer)

    }
    
    @IBAction func resetSession(_ sender: Any) {
        resetTracking()
        
    }
    
 
    @objc func handleTapGesture(sender: UITapGestureRecognizer) {
        if koordGesetzt == true {
            return
        }
    
        let planeHitTestResults = sceneView.hitTest(view.center, types: .existingPlaneUsingExtent)
        
        if let result = planeHitTestResults.first {
            let hitPosition = SCNVector3.positionFromTransform(result.worldTransform)
            ursprung.position = hitPosition
            ursprung.eulerAngles.y = (sceneView.session.currentFrame?.camera.eulerAngles.y)!
            sceneView.scene.rootNode.addChildNode(ursprung)
            setzeKoord()
            koordGesetzt = true
            sessionInfoLabel.text = "Untergrund gefunden"
            focusSquare.hide()
        }
        else {
            ursprung.position = focusSquare.position
            ursprung.eulerAngles.y = (sceneView.session.currentFrame?.camera.eulerAngles.y)!
            sceneView.scene.rootNode.addChildNode(ursprung)
            setzeKoord()
            koordGesetzt = true
            sessionInfoLabel.text = "Koord. gesetzt"
            focusSquare.hide()
        }
    }
    
    @IBAction func qrButtonAction(_ sender: Any) {
        if (koordGesetzt == true && hilfeschritt == 0) {
            objekte.removeAll()
            hilfeschritt = 0
            print(hilfeschritt)
        
            objekte.append(erstelleWuerfel(startpunkt: SCNVector3(0,0,0), nkante: 3) )
            objekte.append(erstelleEbene(startpunkt: SCNVector3(0,0,0), nkanteX: 3, nkanteY:  ((1.5*1.5) + (3*3)).squareRoot() ))
            objekte.append(erstelleGerade(punkt1: SCNVector3(0,0.3,-0.3) , punkt2: SCNVector3(0.3,0,0), radius: 0.001))
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
   
    
    
    @IBAction func addPoint(_ sender: Any) {
        
        if (addX.text != "" && addY.text != "" && addZ.text != ""){
            let neuerPunkt = SCNNode()
            let x = addX.text?.kommaZuPunkt
            let xFloat = (x! as NSString).floatValue
            let y = addY.text?.kommaZuPunkt
            let yFloat = (y! as NSString).floatValue
            let z = addZ.text?.kommaZuPunkt
            let zFloat = (z! as NSString).floatValue
            neuerPunkt.position = SCNVector3(x: xFloat/10*3, y: zFloat/10*3, z: -yFloat/10*3)
            neuerPunkt.geometry = SCNSphere(radius: 0.004)
            neuerPunkt.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            ursprung.addChildNode(neuerPunkt)
            self.view.endEditing(true)
            addX.text = ""
            addY.text = ""
            addZ.text = ""
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
            self.sessionInfoLabel.text = "Kein Hilfeschritt"
            print(hilfeschritt)
        }
    }
    

    
   
    
    private func erstellePunkt (koord: SCNVector3, radiusP: Float) -> SCNNode {
        if koordGesetzt == true {
            let punkt = SCNNode()
            punkt.geometry = SCNSphere(radius: CGFloat(radiusP))
            punkt.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            punkt.position = koord
            return punkt
        }
        else {return ursprung}
    }
    
    private func erstelleGerade (punkt1: SCNVector3, punkt2: SCNVector3, radius: Float)  -> SCNNode {
        if koordGesetzt == true {
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
            zylinder.firstMaterial?.diffuse.contents = UIColor.white
            
            // Mittelpunkt erstellen, bestimmen und zeichnen
            let mittelpunkt = SCNNode()
            mittelpunkt.position = bestimmeGeradenmittelpunkt(a: punkt1, b: punkt2)
            // Zusätzlicher Punkt, um den senkrechten Zylinder in die Waagerechte zu bringen
            let nodeCyl = SCNNode(geometry: zylinder )
            nodeCyl.eulerAngles.x = -.pi / 2
            mittelpunkt.look(at: punkt2)
            
            // Alle Knoten hinzufügen
            
            mittelpunkt.addChildNode(nodeCyl)
            
            return mittelpunkt
        }
        else {return ursprung}
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
            let achsenlaenge: CGFloat = 0.8
            let achsenDicke: CGFloat = 0.0025
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
            
            print ("koord. gesetzt")
            
        }
    }
  
    
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



    // MARK: - ARSessionDelegate
    
    
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        sessionInfoLabel.text = "Anker gelöscht"
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        sessionInfoLabel.text = "Trackingstatus geändert"
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        sessionInfoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        sessionInfoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    // MARK: - Private methods
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        if koordGesetzt == false {
            let message: String
            
            switch trackingState {
            case .normal where frame.anchors.isEmpty:
                // No planes detected; provide instructions for this app's AR interactions.
                message = "Tap Screen to begin"
                
            case .normal:
                // No feedback needed when tracking is normal and planes are visible.
                message = ""
                
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
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
    

    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        // guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
//        if koordGesetzt == false {
//
//            ursprung = node
//            ursprung.eulerAngles.y = self.sceneView.scene.rootNode.eulerAngles.y
//
//            setzeKoord()
//            sessionInfoLabel.text = "Koordinatensystem gesetzt"
//        }
//        else {
//            return
//        }
//
//    }

    

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
