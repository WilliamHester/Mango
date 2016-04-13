//
//  ClassNode.swift
//  Mango
//
//  Created by William Hester on 4/10/16.
//  Copyright © 2016 William Hester. All rights reserved.
//

import Foundation

class ClassNode {

    let name: String
    let superName: String
    var constructors = Set<Constructor>()

    init(name: String, superName: String) {
        self.name = name
        self.superName = superName
    }

    func addConstructor(constructor: Constructor) {
        constructors.insert(constructor)
    }

    class Constructor : NSObject {
        
        // Parameters should be of the format (name, Type)
        let parameters: [(String, String)]

        init(params: [(String, String)]) {
            self.parameters = params
        }

        override var hash: Int {
            var sum = 0
            for param in parameters {
                let (first, second) = param
                sum += first.hashValue + second.hashValue
            }
            return sum
        }

        override func isEqual(object: AnyObject?) -> Bool {
            if let other = object as? Constructor {
                if other.parameters.count != self.parameters.count {
                    return false
                }
                for i in 0..<self.parameters.count {
                    if other.parameters[i] != self.parameters[i] {
                        return false
                    }
                }
                return true
            }
            return false
        }
    }
}
