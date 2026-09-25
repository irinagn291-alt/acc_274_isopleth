import Foundation

/// Role: YearPlate. Codable YearPlate projection. MoodEntry map, twelve tones, schemaVersion.
struct PlateDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var year: Int
    var entries: [MoodEntry]
    var tones: [Tone]
    var onboardingComplete: Bool

    static func empty(year: Int) -> PlateDocument {
        PlateDocument(
            schemaVersion: PlateCodec.currentSchema,
            year: year,
            entries: [],
            tones: ToneWell.factory,
            onboardingComplete: false
        )
    }

    var entryMap: [Int: MoodEntry] {
        var map: [Int: MoodEntry] = [:]
        for entry in entries {
            map[entry.dayKey] = entry
        }
        return map
    }
}

/// Role: YearPlate. Schema switch and encode/decode. No UserDefaults here.
enum PlateCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ document: PlateDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(normalized(document))
    }

    static func decode(_ data: Data) throws -> PlateDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return normalized(try decoder.decode(PlateDocument.self, from: data))
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func normalized(_ document: PlateDocument) -> PlateDocument {
        var next = document
        next.schemaVersion = currentSchema
        var byDay: [Int: MoodEntry] = [:]
        for entry in document.entries {
            let yearOfKey = entry.dayKey / 10_000
            guard yearOfKey == document.year else { continue }
            guard (0 ..< ToneWell.toneCount).contains(entry.toneIndex) else { continue }
            byDay[entry.dayKey] = MoodEntry(dayKey: entry.dayKey, toneIndex: entry.toneIndex)
        }
        next.entries = byDay.values.sorted { $0.dayKey < $1.dayKey }
        if (try? ToneWell.validated(document.tones)) == nil {
            next.tones = ToneWell.factory
        }
        return next
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
