/*===========================================================================
 EqualsOneToTextColorTransformer.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class EqualsOneToTextColorTransformer: ValueTransformer {
    
    // MARK : - NSValueTransformer overrides
    
    /*==========================================================================*/
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    /*==========================================================================*/
    override func transformedValue( _ value: Any? ) -> Any? {
        guard let intValue = value as? Int else { return NSColor.disabledControlTextColor }
        return ( intValue == 1 ? NSColor.controlTextColor : NSColor.disabledControlTextColor )
    }
}

/*==========================================================================*/
extension NSValueTransformerName {
    public static let equalsOneToTextColorTransformerName = NSValueTransformerName( rawValue: "EqualsOneToTextColorTransformer" )
}
