import SwiftUI

/// Role: YearPlate. App shell. Owns the single YearPlate every view observes.
struct ContentView: View {
    @StateObject private var plate: YearPlate

    init() {
        _plate = StateObject(wrappedValue: PlateLive.make())
    }

    var body: some View {
        PlateCanvas(plate: plate)
            .preferredColorScheme(.dark)
            .tint(PlateColor.accent)
    }
}

#Preview {
    ContentView()
}
