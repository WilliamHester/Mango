//
//  ClassParser.swift
//  Mango
//
//  Created by William Hester on 4/12/16.
//  Copyright © 2016 William Hester. All rights reserved.
//

import Foundation
import Clang_C

class ClassParser {
    
    private func parseDeclaration(declaration: UnsafePointer<CXIdxDeclInfo>) {
        switch (declaration.memory.entityInfo.memory.kind) {
        case CXIdxEntity_ObjCInstanceMethod:
            break
        case CXIdxEntity_ObjCClassMethod:
            break
        default:
            break
        }
    }
    
    private let indexCallback: (@convention(c) (CXClientData, UnsafePointer<CXIdxDeclInfo>) -> ())! =
        { (data, declaration) in
            let mySelf = Unmanaged<ClassParser>
                .fromOpaque(COpaquePointer(data)).takeUnretainedValue()
            if declaration.memory.isContainer > 0 {
                let containerInfo = clang_index_getObjCContainerDeclInfo(declaration)
                if containerInfo != nil {
                    if containerInfo.memory.kind == CXIdxObjCContainer_Interface {
                        let declarationInfo = clang_index_getObjCInterfaceDeclInfo(declaration)
                        if declarationInfo != nil {
                            let superclassInfo = declarationInfo.memory.superInfo
                            let mySelf = Unmanaged<FrameworkDSLGenerator>
                                .fromOpaque(COpaquePointer(data)).takeUnretainedValue()
                            let name = String.fromCString(
                                declaration.memory.entityInfo.memory.name)!
                            var superName: String? = nil
                            if superclassInfo != nil {
                                superName = String.fromCString(
                                    superclassInfo.memory.base.memory.name)
//                                mySelf.addClassToTree(name, superName: superName!)
                            }
                        }
                    }
                }
            } else {
                mySelf.parseDeclaration(declaration)
            }
    }
    
    /*
     * Map classes from superclass to subclasses
     */
    private func genClassTree(classMap: Dictionary<String, Set<String>>, headerFile: String) {
        let indexCallback: (@convention(c) (CXClientData, UnsafePointer<CXIdxDeclInfo>) -> ())! =
            { (data, declaration) in
                if declaration.memory.isContainer > 0 {
                    let containerInfo = clang_index_getObjCContainerDeclInfo(declaration)
                    containerInfo.memory.kind
                    if containerInfo != nil {
                        if containerInfo.memory.kind == CXIdxObjCContainer_Interface {
                            let declarationInfo = clang_index_getObjCInterfaceDeclInfo(declaration)
                            if declarationInfo != nil {
//                                let superclassInfo = declarationInfo.memory.superInfo
//                                let mySelf = Unmanaged<FrameworkDSLGenerator>
//                                    .fromOpaque(COpaquePointer(data)).takeUnretainedValue()
//                                let name = String.fromCString(
//                                    declaration.memory.entityInfo.memory.name)!
//                                var superName: String? = nil
//                                if superclassInfo != nil {
//                                    superName = String.fromCString(
//                                        superclassInfo.memory.base.memory.name)
//                                    mySelf.addClassToTree(name, superName: superName!)
//                                }
                            }
                        }
                    }
                }
        }
        var callbacks = IndexerCallbacks()
        callbacks.indexDeclaration = indexCallback
        
        let index = clang_createIndex(0, 0)
        
//        let uiView = framework + "/Headers/" + headerFile
        
        let args = [
            "-x", "objective-c",
//            "-F" + iOSSDKFrameworkPath
        ]
        
        var translationUnit: CXTranslationUnit = nil
        withCPointerToNullTerminatingCArrayOfCStrings(args) { uArgs in
            let unsafeArgs = UnsafePointer<UnsafePointer<Int8>>(uArgs)
            translationUnit =
                clang_parseTranslationUnit(index,
                                           "", //uiView,
                                           unsafeArgs,
                                           Int32(args.count),
                                           nil,
                                           0,
                                           UInt32(CXTranslationUnit_None.rawValue))
        }
        
        let clientData: UnsafeMutablePointer<Void> =
            UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())
        clang_indexTranslationUnit(clang_IndexAction_create(index),
                                   clientData,
                                   &callbacks,
                                   UInt32(sizeof(callbacks.dynamicType)),
                                   (CXIndexOpt_SuppressWarnings.rawValue |
                                    CXIndexOpt_SuppressRedundantRefs.rawValue),
                                   translationUnit)
        
        clang_disposeTranslationUnit(translationUnit);
        clang_disposeIndex(index);
    }
}