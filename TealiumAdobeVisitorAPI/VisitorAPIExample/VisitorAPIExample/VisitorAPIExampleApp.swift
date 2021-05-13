// 
// VisitorAPIExampleApp.swift
// VisitorAPIExample
//
//  
//

import SwiftUI
import TealiumSwift
import TealiumAdobeVisitorAPI

@main
struct VisitorAPIExampleApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
    
}
