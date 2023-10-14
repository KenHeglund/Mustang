/*===========================================================================
 AppDelegate.swift
 Mustang
 Copyright (c) 2016,2023 OrderedBytes. All rights reserved.
 ===========================================================================*/

import AppKit


// MARK: - AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		ValueTransformer.setValueTransformer(EqualsOneToBoolTransformer(), forName: EqualsOneToBoolTransformer.name)
		ValueTransformer.setValueTransformer(EqualsOneToTextColorTransformer(), forName: EqualsOneToTextColorTransformer.name)
		ValueTransformer.setValueTransformer(IsNotZeroTransformer(), forName: IsNotZeroTransformer.name)
	}
}
