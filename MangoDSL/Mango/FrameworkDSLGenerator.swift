//
// Created by William Hester on 4/10/16.
// Copyright (c) 2016 William Hester. All rights reserved.
//

import Foundation
import Clang_C

class FrameworkDSLGenerator {

    private let frameworkPath = "/Applications/Xcode.app/Contents/Developer/Platforms/" +
        	"iPhoneOS.platform/Developer/SDKs/iPhoneOS9.3.sdk/System/Library/Frameworks/"
    let framework: String
    var classMap = Dictionary<String, Set<String>>()
    var viewsList = [String]()

    init(framework: String) {
        self.framework = frameworkPath + framework + ".framework"
    }
    
    private func getSubclasses(type: String) {
        viewsList.append(type)
        if classMap[type] != nil {
            for clazz in classMap[type]! {
                getSubclasses(clazz)
            }
        }
    }

    func run() {
        let headerFiles = listHeaderFiles()
        for file in headerFiles {
            genClassTree(classMap, headerFile: file)
        }
        getSubclasses("UIView")
        
        printBegin()
        printExtensionFunctions()
        printEnd()
    }
    
    private func printBegin() {
        var header = "// Generated code by Mango\n\n"
        header += "import UIKit\n\n"
        header += "extension UIView {\n\n"
        header += "    internal func addChild(view: UIView) {\n"
        header += "        addSubview(view)\n"
        header += "    }\n\n"
        print(header)
    }
    
    private func printEnd() {
        var end = "}\n\n"
        end += "extension UIStackView {\n"
        end += "    override internal func addChild(view: UIView) {\n"
        end += "        addSubview(view)\n"
        end += "    }\n"
        end += "}\n"
        print(end)
    }
    
    private func classNameToFunctionName(name: String) -> String {
        var index = 0
        var splitIdx = 1
        for char in name.characters {
            if char >= "a" && char <= "z" {
                splitIdx = max(index - 1, splitIdx)
                break
            }
            index += 1
        }
        let ind = name.startIndex.advancedBy(splitIdx)
        return name.substringToIndex(ind).lowercaseString + name.substringFromIndex(ind)
    }
    
    private func printExtensionFunctions() {
        var functions = ""
        for clazz in viewsList {
            functions += "    func \(classNameToFunctionName(clazz))(views: (\(clazz)) -> ()) -> " +
                "\(clazz) {\n"
            functions += "        let view = \(clazz)()\n"
            functions += "        views(view)\n"
            functions += "        addChild(view)\n"
            functions += "        return view\n"
            functions += "    }\n\n"
        }
        print(functions)
    }

    private func listHeaderFiles() -> [String] {
        var headerFiles = [String]()
        let fileManager = NSFileManager.defaultManager()
        let enumerator = fileManager.enumeratorAtPath(framework + "/Headers")

        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".h") {
                headerFiles.append(element)
            }
        }
        return headerFiles
    }
    
    private func addClassToTree(name: String, superName: String) {
        if classMap[superName] == nil {
            classMap[superName] = Set<String>()
        }
        classMap[superName]?.insert(name)
    }

    /*
     * Map classes from superclass to subclasses
     */
    private func genClassTree(classMap: Dictionary<String, Set<String>>, headerFile: String) {
        let indexCallback: (@convention(c) (CXClientData, UnsafePointer<CXIdxDeclInfo>) -> Void)! =
        { (data, declaration) in
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
                                mySelf.addClassToTree(name, superName: superName!)
                            }
                        }
                    }
                }
            }
        }
        var callbacks = IndexerCallbacks()
        callbacks.indexDeclaration = indexCallback

        let index = clang_createIndex(0, 0)

        let uiView = framework + "/Headers/" + headerFile

        let args = [
                "-x", "objective-c",
                "-F" + frameworkPath
        ]

    	var translationUnit: CXTranslationUnit = nil
        withCPointerToNullTerminatingCArrayOfCStrings(args) { uArgs in
            let unsafeArgs = UnsafePointer<UnsafePointer<Int8>>(uArgs)
            translationUnit =
                clang_parseTranslationUnit(index,
                                           uiView,
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
