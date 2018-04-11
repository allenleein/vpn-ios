//
//  AppPreferences.swift
//  PIA VPN
//
//  Created by Davide De Rosa on 12/16/17.
//  Copyright © 2017 London Trust Media. All rights reserved.
//

import Foundation
import PIALibrary
import SwiftyBeaver

private let log = SwiftyBeaver.self

class AppPreferences {
    private struct Entries {
        static let version = "Version"
        
        static let launched = "Launched" // discard 2.2 key and invert logic
        
        static let seenContentBlocker = "SeenContentBlocker"
        
        static let didAskToEnableNotifications = "DidAskToEnableNotifications"

        static let themeCode = "Theme" // reuse 2.2 key

        static let lastVPNConnectionStatus = "LastVPNConnectionStatus"
    }

    static let shared = AppPreferences()
    
    private static let currentVersion = "3.0"
    
    private let defaults: UserDefaults

    var wasLaunched: Bool {
        get {
            return defaults.bool(forKey: Entries.launched)
        }
        set {
            defaults.set(newValue, forKey: Entries.launched)
        }
    }
    
    var didSeeContentBlocker: Bool {
        get {
            return defaults.bool(forKey: Entries.seenContentBlocker)
        }
        set {
            defaults.set(newValue, forKey: Entries.seenContentBlocker)
        }
    }
    
    var didAskToEnableNotifications: Bool {
        get {
            return defaults.bool(forKey: Entries.didAskToEnableNotifications)
        }
        set {
            defaults.set(newValue, forKey: Entries.didAskToEnableNotifications)
        }
    }
    
    var currentThemeCode: ThemeCode {
        get {
            let rawCode = defaults.integer(forKey: Entries.themeCode)
            return ThemeCode(rawValue: rawCode) ?? .light
        }
        set {
            defaults.set(newValue.rawValue, forKey: Entries.themeCode)
        }
    }
    
    var lastVPNConnectionStatus: VPNStatus {
        get {
            guard let rawValue = defaults.string(forKey: Entries.lastVPNConnectionStatus) else {
                return .disconnected
            }
            return VPNStatus(rawValue: rawValue) ?? .disconnected
        }
        set {
            defaults.set(newValue.rawValue, forKey: Entries.lastVPNConnectionStatus)
        }
    }

    private init() {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroup) else {
            fatalError("Unable to initialize app preferences")
        }
        self.defaults = defaults

        defaults.register(defaults: [
            Entries.version: AppPreferences.currentVersion,
            Entries.launched: false,
            Entries.didAskToEnableNotifications: false,
            Entries.themeCode: ThemeCode.light.rawValue
        ])
    }
    
    func migrate() {
        let oldVersion = defaults.string(forKey: Entries.version)
        defaults.set(AppPreferences.currentVersion, forKey: Entries.version)
        
        guard (oldVersion == nil) else {
            // migration to 3.0
            return
        }

        // new install or app version < 2.1
        let oldDefaults = UserDefaults.standard
        
        // migrate username to new key
        let legacyUsername = oldDefaults.string(forKey: "Username")
        var maybeLoggedUsername = oldDefaults.string(forKey: "LoggedUsername")
        if ((legacyUsername != nil) && (maybeLoggedUsername == nil)) {
            oldDefaults.removeObject(forKey: "Username")
            maybeLoggedUsername = legacyUsername
        }
        
        // no old login means logged out or new install, no migration needed
        guard let loggedUsername = maybeLoggedUsername else {
            return
        }
        
        // otherwise, app version < 2.1 (local defaults/keychain)
        
        // it used to be here in app version <= 2.0
        let oldKeychain = Keychain()
        let newKeychain = Keychain(team: AppConstants.teamId, group: AppConstants.appGroup)
        
        // migrate credentials from local to shared keychain
        if let legacyPassword = try? oldKeychain.password(for: loggedUsername) {
            oldDefaults.removeObject(forKey: "Username")
            oldDefaults.removeObject(forKey: "LoggedUsername")
            oldKeychain.removePassword(for: loggedUsername)
            
            // store to new defaults/keychain
            defaults.set(loggedUsername, forKey: "LoggedUsername")
            try? newKeychain.set(password: legacyPassword, for: loggedUsername)
        }
        
        // migrate settings
        wasLaunched = !oldDefaults.bool(forKey: "FirstLaunch")
        didAskToEnableNotifications = oldDefaults.bool(forKey: Entries.didAskToEnableNotifications)
        
        // discard these, will be fetched on login
//        NSString *subscriptionExpirationDate = [oldDefaults objectForKey:@"SubscriptionExpirationDate"];
//        NSString *subscriptionPlan = [oldDefaults objectForKey:@"SubscriptionPlan"];
        oldDefaults.removeObject(forKey: "SubscriptionExpirationDate")
        oldDefaults.removeObject(forKey: "SubscriptionPlan")
    }

    func reset() {
    }
    
//    + (void)eraseForTesting;
}
