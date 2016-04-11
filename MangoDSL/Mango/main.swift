//
//  main.swift
//  Mango
//
//  Created by William Hester on 4/7/16.
//  Copyright © 2016 William Hester. All rights reserved.
//
import Foundation
import Clang_C

extension NSData {
    ///	Assumes `cCharacters` is C-string.
    class func fromCCharArray(cCharacters:[CChar]) -> NSData {
        precondition(cCharacters.count == 0 || cCharacters[cCharacters.endIndex.predecessor()] == 0)
        var	r	=	nil as NSData?
        cCharacters.withUnsafeBufferPointer { (p:UnsafeBufferPointer<CChar>) -> () in
            let	p1	=	UnsafePointer<Void>(p.baseAddress)
            r		=	NSData(bytes: p1, length: p.count)
        }
        return	r!
    }
}

extension CXString {
    func toString() -> String {
        return String.fromCString(clang_getCString(self))!
    }
}


let indexDeclarationCallback: (@convention(c) (CXClientData, UnsafePointer<CXIdxDeclInfo>) -> Void)! = { (data, declaration) in
    
    if declaration.memory.isContainer > 0 {
        let containerInfo = clang_index_getObjCContainerDeclInfo(declaration)
        
        if containerInfo != nil {
            if containerInfo.memory.kind == CXIdxObjCContainer_Interface {
                let declarationInfo = clang_index_getObjCInterfaceDeclInfo(declaration)
                if declarationInfo != nil {
                    let superclassInfo = declarationInfo.memory.superInfo
                    let name = String.fromCString(declaration.memory.entityInfo.memory.name)!
                    print(name)
                    var superName: String? = nil
                    if superclassInfo != nil {
                        superName = String.fromCString(superclassInfo.memory.base.memory.name)
                        print(name, ":", superName!)
                    } else {
                        print(name)
                    }
                }
            }
        }
    }
}

var callbacks = IndexerCallbacks()
callbacks.indexDeclaration = indexDeclarationCallback

func withCPointerToNullTerminatingCArrayOfCStrings(strings:[String], _ block:(UnsafePointer<UnsafeMutablePointer<Int8>>)->()) {
    ///	Keep this in memory until the `block` to be finished.
    let	a	=	strings.map { (s:String) -> NSMutableData in
        let	b	=	s.cStringUsingEncoding(NSUTF8StringEncoding)!
        assert(b[b.endIndex-1] == 0)
        return	NSData.fromCCharArray(b).mutableCopy() as! NSMutableData
    }
    
    let	a1	=	a.map { (d:NSMutableData) -> UnsafeMutablePointer<Int8> in
        return	UnsafeMutablePointer<Int8>(d.mutableBytes)
        } + [nil as UnsafeMutablePointer<Int8>]
    
    a1.withUnsafeBufferPointer { (p:UnsafeBufferPointer<UnsafeMutablePointer<Int8>>) -> () in
        block(p.baseAddress)
    }
}

let index = clang_createIndex(0, 0)

let uiView = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/" +
"Developer/SDKs/iPhoneOS9.3.sdk/System/Library/Frameworks/UIKit.framework/Headers/UITabBar.h"

let args = [
    "-x", "objective-c",
    "-F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk/System/Library/Frameworks"
]

var translationUnit: CXTranslationUnit = nil
withCPointerToNullTerminatingCArrayOfCStrings(args) { uArgs in
    let unsafeArgs = UnsafePointer<UnsafePointer<Int8>>(uArgs)
    translationUnit = clang_parseTranslationUnit(index, uiView, unsafeArgs, Int32(args.count), nil, 0, UInt32(CXTranslationUnit_None.rawValue))
}

clang_indexTranslationUnit(clang_IndexAction_create(index), nil, &callbacks, UInt32(sizeof(callbacks.dynamicType)), (CXIndexOpt_SuppressWarnings.rawValue | CXIndexOpt_SuppressRedundantRefs.rawValue), translationUnit)

clang_disposeTranslationUnit(translationUnit);
clang_disposeIndex(index);
