//
// Created by William Hester on 4/10/16.
// Copyright (c) 2016 William Hester. All rights reserved.
//

import Foundation

extension NSData {
    /// Assumes `cCharacters` is C-string.
    class func fromCCharArray(cCharacters:[CChar]) -> NSData {
        precondition(cCharacters.count == 0 || cCharacters[cCharacters.endIndex.predecessor()] == 0)
        var r = nil as NSData?
        cCharacters.withUnsafeBufferPointer { (p:UnsafeBufferPointer<CChar>) -> () in
            let p1 = UnsafePointer<Void>(p.baseAddress)
            r = NSData(bytes: p1, length: p.count)
        }
        return r!
    }
}

func withCPointerToNullTerminatingCArrayOfCStrings(strings:[String], _ block:(UnsafePointer<UnsafeMutablePointer<Int8>>)->()) {
    /// Keep this in memory until the `block` to be finished.
    let a = strings.map { (s:String) -> NSMutableData in
        let b = s.cStringUsingEncoding(NSUTF8StringEncoding)!
        assert(b[b.endIndex-1] == 0)
        return NSData.fromCCharArray(b).mutableCopy() as! NSMutableData
    }

    let a1 = a.map { (d:NSMutableData) -> UnsafeMutablePointer<Int8> in
        return UnsafeMutablePointer<Int8>(d.mutableBytes)
    } + [nil as UnsafeMutablePointer<Int8>]

    a1.withUnsafeBufferPointer { (p:UnsafeBufferPointer<UnsafeMutablePointer<Int8>>) -> () in
        block(p.baseAddress)
    }
}

