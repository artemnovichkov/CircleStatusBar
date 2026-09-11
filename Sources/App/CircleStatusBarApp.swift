import SwiftUI

@main
struct CircleStatusBarApp: App {
    var body: some Scene {
        WindowGroup {
            PlayerView()
                #if os(macOS)
                .frame(minWidth: 480, minHeight: 360)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 960, height: 640)
        #endif
    }
}
