/*===========================================================================
 EqualsOneToTextColorTransformer.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class EqualsOneToTextColorTransformer: NSValueTransformer {
    
    // MARK : - NSValueTransformer overrides
    
    /*==========================================================================*/
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    /*==========================================================================*/
    override func transformedValue( value: AnyObject? ) -> AnyObject? {
        guard let intValue = value as? Int else { return NSColor.disabledControlTextColor() }
        return ( intValue == 1 ? NSColor.controlTextColor() : NSColor.disabledControlTextColor() )
    }
}
