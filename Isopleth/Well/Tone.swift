import Foundation

/// Role: Well. One spoken tone in the twelve-tone well. Colour is never the only signal.
struct Tone: Hashable, Sendable, Codable, Identifiable, Equatable {
    var spokenName: String
    var red: Double
    var green: Double
    var blue: Double

    var id: String { spokenName }
}

/// Role: Well. Twelve named tones. Settings may rewrite names and inks, never the count.
enum ToneWell {
    static let toneCount = 12

    static let factory: [Tone] = [
        Tone(spokenName: "Still", red: 0.369, green: 0.537, blue: 0.910),
        Tone(spokenName: "Drift", red: 0.745, green: 0.780, blue: 0.820),
        Tone(spokenName: "Lift", red: 0.459, green: 0.588, blue: 0.918),
        Tone(spokenName: "Crest", red: 0.780, green: 0.827, blue: 0.847),
        Tone(spokenName: "Fold", red: 0.545, green: 0.655, blue: 0.925),
        Tone(spokenName: "Spur", red: 0.816, green: 0.839, blue: 0.875),
        Tone(spokenName: "Scarp", red: 0.635, green: 0.737, blue: 0.933),
        Tone(spokenName: "Bench", red: 0.851, green: 0.871, blue: 0.902),
        Tone(spokenName: "Sill", red: 0.725, green: 0.788, blue: 0.937),
        Tone(spokenName: "Notch", red: 0.886, green: 0.918, blue: 0.929),
        Tone(spokenName: "Rim", red: 0.816, green: 0.855, blue: 0.945),
        Tone(spokenName: "Peak", red: 0.918, green: 0.929, blue: 0.961),
    ]

    static func validated(_ tones: [Tone]) throws -> [Tone] {
        guard tones.count == toneCount else { throw PlateError.invalidWell }
        var names = Set<String>()
        for tone in tones {
            let name = tone.spokenName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, names.insert(name).inserted else { throw PlateError.invalidWell }
            try validateInk(tone)
        }
        return tones
    }

    static func validateInk(_ tone: Tone) throws {
        for channel in [tone.red, tone.green, tone.blue] {
            guard channel.isFinite, (0 ... 1).contains(channel) else { throw PlateError.invalidWell }
        }
    }

    static func renaming(_ tones: [Tone], at index: Int, spokenName: String) throws -> [Tone] {
        guard tones.count == toneCount, tones.indices.contains(index) else {
            throw PlateError.invalidWell
        }
        var next = tones
        next[index].spokenName = spokenName.trimmingCharacters(in: .whitespacesAndNewlines)
        return try validated(next)
    }

    static func advancingInk(_ tones: [Tone], at index: Int) throws -> [Tone] {
        guard tones.count == toneCount, tones.indices.contains(index) else {
            throw PlateError.invalidWell
        }
        var next = tones
        let current = next[index]
        let ladder = factory
        let ink: Tone
        if let match = ladder.firstIndex(where: { sameInk($0, current) }) {
            ink = ladder[(match + 1) % ladder.count]
        } else {
            ink = ladder[0]
        }
        next[index] = Tone(
            spokenName: current.spokenName,
            red: ink.red,
            green: ink.green,
            blue: ink.blue
        )
        return try validated(next)
    }

    /// Written name of the wash, matched to the factory ink ladder. Colour is never the only signal.
    static func inkSpokenName(_ tone: Tone) -> String {
        let names = [
            "Cobalt", "Ash", "Cornflower", "Mist",
            "Periwinkle", "Pearl", "Ice", "Silver",
            "Powder", "Fog", "Lilac", "Snow",
        ]
        if let match = factory.firstIndex(where: { sameInk($0, tone) }), names.indices.contains(match) {
            return names[match]
        }
        return "Custom"
    }

    private static func sameInk(_ a: Tone, _ b: Tone) -> Bool {
        abs(a.red - b.red) < 0.001
            && abs(a.green - b.green) < 0.001
            && abs(a.blue - b.blue) < 0.001
    }
}
