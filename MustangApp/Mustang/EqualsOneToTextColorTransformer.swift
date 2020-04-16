/*===========================================================================
EqualsOneToTextColorTransformer.swift
Mustang
Copyright (c) 2016 OrderedBytes. All rights reserved.
===========================================================================*/

import Cocoa

/*==========================================================================*/

class EqualsOneToTextColorTransformer: ValueTransformer {
	
	static let name = NSValueTransformerName(rawValue: "EqualsOneToTextColorTransformer")
	
	// MARK: - NSValueTransformer overrides
	
	/*==========================================================================*/
	override class func allowsReverseTransformation() -> Bool {
		false
	}
	
	/*==========================================================================*/
	override func transformedValue( _ value: Any? ) -> Any? {
		guard let intValue = value as? Int else {
			return NSColor.disabledControlTextColor
		}
		
		return (intValue == 1 ? NSColor.controlTextColor : NSColor.disabledControlTextColor)
	}
}
