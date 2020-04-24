/*===========================================================================
IsNotZeroTransformer.swift
Mustang
Copyright (c) 2016 OrderedBytes. All rights reserved.
===========================================================================*/

import Cocoa

/*==========================================================================*/

class IsNotZeroTransformer: ValueTransformer {
	
	static let name = NSValueTransformerName(rawValue: "IsNotZeroTransformer")
	
	// MARK: - NSValueTransformer overrides
	
	/*==========================================================================*/
	override class func allowsReverseTransformation() -> Bool {
		false
	}
	
	/*==========================================================================*/
	override func transformedValue(_ value: Any?) -> Any? {
		if let intValue = value as? Int, intValue != 0 {
			return true
		}
		else {
			return false
		}
	}
}
