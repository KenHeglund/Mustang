/*===========================================================================
 IsNotZeroTransformer.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class IsNotZeroTransformer: NSValueTransformer {
    
    // MARK: - NSValueTransformer overrides
    
    /*==========================================================================*/
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    /*==========================================================================*/
    override func transformedValue( value: AnyObject? ) -> AnyObject? {
        guard let intValue = value as? Int else { return false }
        return intValue != 0
    }
}
