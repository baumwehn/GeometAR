//
//  VirtualObject.swift
//  GeometAR
//
//  Created by Birnbaum on 17.05.18.
//  Copyright © 2018 IDMI. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class GeoObject: SCNNode {
    let modelName: String
    let displayName: String
    var displayImage: UIImage
    
    
    
    init (modelName: String, displayName: String, displayImage: UIImage){
        self.modelName = modelName
        self.displayName = displayName
        self.displayImage = displayImage
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
