/*===========================================================================
 AppDelegate.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    /*==========================================================================*/
    override func awakeFromNib() {
        NSValueTransformer.setValueTransformer( EqualsOneToBoolTransformer(), forName: "EqualsOneToBoolTransformer" )
        NSValueTransformer.setValueTransformer( EqualsOneToTextColorTransformer(), forName: "EqualsOneToTextColorTransformer" )
        NSValueTransformer.setValueTransformer( IsNotZeroTransformer(), forName: "IsNotZeroTransformer" )
    }
    
    /*==========================================================================*/
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    /*==========================================================================*/
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}
