import UIKit
import Alamofire
import OneSignalFramework

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let bind = "com.isopleth.ridge"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = Self.bind
        APIConfig.apply()
        OneSignal.initialize("eca64790-b09f-4c16-9065-043a0f51fc02", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ @Sendable _ in }, fallbackToSettings: false)
        application.registerForRemoteNotifications()
        return true
    }
}
