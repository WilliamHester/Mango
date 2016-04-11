//
//  ClassNode.swift
//  Mango
//
//  Created by William Hester on 4/10/16.
//  Copyright © 2016 William Hester. All rights reserved.
//

import Foundation

class ClassNode {
    var name: String
    var superName: String
    
    init(name: String, superName: String) {
        self.name = name
        self.superName = superName
    }
}
