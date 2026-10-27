import Foundation

umask(0o077)
do {
    switch CommandLine.arguments.dropFirst().first {
    case "watch": watch()
    case "list": try list()
    case "copy": try copy()
    case "clear": try clear()
    default: throw ClipVaultError(description: "usage: clipvault watch | list | copy | clear")
    }
} catch {
    FileHandle.standardError.write(Data((describe(error) + "\n").utf8))
    exit(1)
}
