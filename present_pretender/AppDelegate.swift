//
//  AppDelegate.swift
//  present_pretender
//
//  Created by rnitta on 2019/12/27.
//  Copyright © 2019 rnitta. All rights reserved.
//

import Cocoa
import IOKit
import IOKit.pwr_mgt

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menu: MenuBarIcon!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var menuBarHeight: Optional<CGFloat> { NSApplication.shared.mainMenu?.menuBarHeight }
    var latestMovedAt = NSDate()
    var moveEventTimer = Timer()
    var threasholdMinutes = 30

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        menu.initialize()
        
        // set icon
        if let menuBarHeight = menuBarHeight {
            if let icon = NSImage(named: "Black") {
                icon.size = NSSize(width: menuBarHeight, height: menuBarHeight)
                statusItem.button?.image = icon
            }
        }
        statusItem.menu = menu

        // monitor and record latest mouse movement time
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            self.latestMovedAt = NSDate()
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    private var _autoMoveEnabled = false
    var autoMoveEnabled:Bool  {
        get { return _autoMoveEnabled }
        set(v) {
            if _autoMoveEnabled == v {return}
            _autoMoveEnabled = v
            updateIcon()
            if v {
                // sending mouse event programatically will require "accessibility permissions" (probably with Mojave and later), and the prompt screen will appear once an event sent.
                sendMoveMouseEvent()
                // fixme: doesnt seem to be fired 1 sec after approx 1 minute elapsed
                moveEventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: checkShouldMove(_:))
                
            } else {
                moveEventTimer.invalidate()
            }
            
        }
    }
    
    // check if the time elapsed from latest activity exceed the threashold.
    @objc func checkShouldMove(_ sender:Timer) {
        let diff = Int(NSDate().timeIntervalSince(latestMovedAt as Date))
        if diff > threasholdMinutes * 60 {
            sendMoveMouseEvent()
        }
    }

    // just send "event". pointer location will not change.
    func sendMoveMouseEvent() {
        // fixme: these code may be problematic if you use multi-display
        guard let screen = NSScreen.main else {
            return
        }
        
        let currentMousePos = NSEvent.mouseLocation
        guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: currentMousePos.x, y: screen.frame.height - currentMousePos.y), mouseButton: .left) else {
            return
        }
        moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    let reasonForActivity = "DISABLE SLEEP" as CFString
    var assertionID: IOPMAssertionID = 0
    var ioret: Optional<IOReturn> = nil
    private var _isSleepDisabled = false
    var isSleepDisabled: Bool {
        get { return _isSleepDisabled }
        set(v) {
            if _isSleepDisabled == v { return }
            _isSleepDisabled = v
            updateIcon()
            if v {
                ioret = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reasonForActivity,
                &assertionID )
            } else {
                ioret = IOPMAssertionRelease(assertionID)
            }

        }
    }
    
    func updateIcon() {
        let statusEnum: IsOn = {
            switch (autoMoveEnabled, isSleepDisabled) {
        case (true, true):
            return IsOn.Both
        case (false, false):
            return IsOn.None
        default:
            return IsOn.Partially
            }
        }()
        
        if let menuBarHeight = menuBarHeight {
            let iconName: String = {
                switch statusEnum {
                case .Both:
                    return "Green"
                case .Partially:
                    return "Orange"
                case .None:
                    return "Black"
                }
            }()
            if let icon = NSImage(named: iconName) {
                icon.size = NSSize(width: menuBarHeight, height: menuBarHeight)
                statusItem.button?.image = icon
            }
        }
    }
}

enum IsOn {
    case None
    case Partially
    case Both
}
