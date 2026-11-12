import Foundation
import ThemeCore

// Usage: theme-cli validate [--base <base.json>] [--json] <theme.json>...
let usage = "usage: theme-cli validate [--base <base.json>] [--json] <theme.json>..."
var args = Array(CommandLine.arguments.dropFirst())

guard args.first == "validate" else {
    FileHandle.standardError.write(Data((usage + "\n").utf8))
    exit(2)
}
args.removeFirst()

var baseURL: URL?
var jsonOutput = false
var files = [String]()
while !args.isEmpty {
    let arg = args.removeFirst()
    switch arg {
    case "--base":
        guard !args.isEmpty else { fputs(usage + "\n", stderr); exit(2) }
        baseURL = URL(fileURLWithPath: args.removeFirst())
    case "--json":
        jsonOutput = true
    default:
        files.append(arg)
    }
}
guard !files.isEmpty else { fputs(usage + "\n", stderr); exit(2) }

var report = [String: [String]]()
do {
    let baseData = try baseURL.map { try Data(contentsOf: $0) }
    for file in files {
        let data = try Data(contentsOf: URL(fileURLWithPath: file))
        report[file] = try ThemeValidation.validate(data, base: baseData)
    }
} catch {
    fputs("error: \(error)\n", stderr)
    exit(2)
}

let failed = report.values.contains { !$0.isEmpty }
if jsonOutput {
    let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    print(String(decoding: data, as: UTF8.self))
} else {
    for (file, issues) in report.sorted(by: { $0.key < $1.key }) {
        print(issues.isEmpty ? "OK   \(file)" : "FAIL \(file)")
        issues.forEach { print("  \($0)") }
    }
}
exit(failed ? 1 : 0)
