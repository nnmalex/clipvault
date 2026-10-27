import Foundation
import LocalAuthentication
import Security

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("Test failed: \(message)\n".utf8))
        exit(1)
    }
}

// A failed clipboard change is retried after the maintenance interval, while a newer change
// bypasses the backoff immediately.
let start = Date(timeIntervalSinceReferenceDate: 1_000)
var watchState = WatchState(capturedChange: 10)
expect(!watchState.shouldCapture(change: 10, at: start), "captured changes must not repeat")
expect(watchState.shouldCapture(change: 11, at: start), "new changes must be captured immediately")
watchState.recordCapture(change: 11, at: start, succeeded: false)
expect(!watchState.shouldCapture(change: 11, at: start.addingTimeInterval(59)), "failed changes need backoff")
expect(watchState.shouldCapture(change: 11, at: start.addingTimeInterval(60)), "failed changes must retry")
expect(watchState.shouldCapture(change: 12, at: start.addingTimeInterval(1)), "newer changes bypass backoff")
watchState.recordCapture(change: 12, at: start.addingTimeInterval(1), succeeded: true)
expect(!watchState.shouldCapture(change: 12, at: start.addingTimeInterval(120)), "successful changes must stay captured")

// Preview output must not contain terminal controls or Unicode formatting controls.
let sanitized = preview("safe\u{1B}]52;c;bad\u{07}\u{202E} text")
expect(sanitized == "safe ]52;c;bad text", "preview sanitization")
expect(sanitized.unicodeScalars.allSatisfy(isPrintable), "preview contains unsafe scalars")

// Legacy entries without ids must decode and remain encodable after migration.
struct LegacyEntry: Codable {
    var text: String
    var date: Date
}
let legacyData = try JSONEncoder().encode([
    LegacyEntry(text: "existing", date: Date(timeIntervalSinceReferenceDate: 1)),
])
var migrated = try JSONDecoder().decode([Entry].self, from: legacyData)
expect(migrated[0].id.isEmpty, "legacy entry should request an id")
migrated[0].id = "abcdef"
let roundTrip = try JSONDecoder().decode([Entry].self, from: JSONEncoder().encode(migrated))
expect(roundTrip[0].id == "abcdef", "migrated id did not persist")

// Noninteractive Keychain operations must use an LAContext instead of a deprecated global switch.
let interactive = keychainItem("test", allowInteraction: true)
expect(interactive[kSecUseAuthenticationContext as String] == nil, "interactive query has a context")
let noninteractive = keychainItem("test", allowInteraction: false)
let context = noninteractive[kSecUseAuthenticationContext as String] as? LAContext
expect(context?.interactionNotAllowed == true, "noninteractive query allows interaction")

print("Swift tests passed.")
