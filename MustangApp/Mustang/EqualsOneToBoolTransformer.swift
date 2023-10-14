/*===========================================================================
 EqualsOneToBoolTransformer.swift
 Mustang
 Copyright (c) 2016,2023 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Foundation


// MARK: - EqualsOneToBoolTransformer

class EqualsOneToBoolTransformer: ValueTransformer {
	static let name = NSValueTransformerName(rawValue: "EqualsOneToBoolTransformer")
	
	override class func allowsReverseTransformation() -> Bool {
		false
	}
	
	override func transformedValue(_ value: Any?) -> Any? {
		if let intValue = value as? Int, intValue == 1 {
			return true
		} else {
			return false
		}
	}
}
