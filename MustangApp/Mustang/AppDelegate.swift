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
        ValueTransformer.setValueTransformer( EqualsOneToBoolTransformer(), forName: .equalsOneToBoolTransformerName )
        ValueTransformer.setValueTransformer( EqualsOneToTextColorTransformer(), forName: .equalsOneToTextColorTransformerName )
        ValueTransformer.setValueTransformer( IsNotZeroTransformer(), forName: .isNotZeroTransformerName )
    }
    
    /*==========================================================================*/
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    /*==========================================================================*/
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}
