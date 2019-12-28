//
//  MenuBarIcon.swift
//  present_pretender
//
//  Created by rnitta on 2019/12/28.
//  Copyright © 2019 rnitta. All rights reserved.
//

import Cocoa


// the icon button on the menu bar.
class MenuBarIcon: NSMenu {
    @IBOutlet weak var sleepDisableView: NSView!
    @IBOutlet weak var sleepDisableCheckbox: NSButton!
    @IBOutlet weak var autoMovePointerView: NSView!
    @IBOutlet weak var autoMoveCheckbox: NSButton!
    @IBOutlet weak var autoMoveIntervalSlider: NSSlider!
    @IBOutlet weak var autoMoveLabel: NSTextField!
    
    @IBAction func autoMoveChecboxOnChange(_ sender: NSButton) {
        let isOn = sender.state == NSControl.StateValue.on
        self.autoMoveEnabled = isOn
    }
    
    @IBAction func autoMoveIntervalSliderOnChange(_ sender: NSSlider) {
        app.threasholdMinutes = Int(sender.intValue)
        autoMoveLabel.stringValue = """
Every \(sender.intValue) Minutes
(if no activity detected)
"""
    }
    private var app: AppDelegate { NSApplication.shared.delegate as! AppDelegate }
    private var _autoMoveEnabled = false
    var autoMoveEnabled:Bool  {
        get {return _autoMoveEnabled}
        set(v) {
            _autoMoveEnabled = v
            autoMoveIntervalSlider.isEnabled = v
            autoMoveLabel.textColor = v ? NSColor.black : NSColor.gray
            app.autoMoveEnabled = v
        }
    }
    

    @IBAction func disableSleepOnChecked(_ sender: NSButton) {
        app.isSleepDisabled = sender.state == .on
    }
    
    // called manually in AppDelegate. There might be better way to set up.
    func initialize() {
        let menuItem1 = NSMenuItem()
        menuItem1.title = "Disable Sleep"
        menuItem1.view = sleepDisableView
        self.addItem(menuItem1)

        self.addItem(NSMenuItem.separator())

        
        let menuItem2 = NSMenuItem()
        menuItem2.title = "Auto Move Pointer"
        menuItem2.view = autoMovePointerView
        autoMoveEnabled = false
        self.addItem(menuItem2)
    }
        
}
