#!/usr/bin/env swift
// Renders the 🍯 emoji centered on a fully transparent canvas at all AppIcon
// sizes, then invokes `iconutil` to produce Resources/AppIcon.icns.

import AppKit

let emoji = "🍯"
let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]

let fm = FileManager.default
let iconset = URL(fileURLWithPath: "build/AppIcon.iconset", isDirectory: true)
let outIcns = URL(fileURLWithPath: "Resources/AppIcon.icns")

try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
try? fm.createDirectory(at: outIcns.deletingLastPathComponent(), withIntermediateDirectories: true)

func render(size: Int) -> Data {
    let px = CGFloat(size)
    let image = NSImage(size: NSSize(width: px, height: px))
    image.lockFocus()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: px, height: px).fill()

    // Font size chosen so the emoji glyph fills ~88% of the canvas.
    let fontSize = px * 0.82
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize)
    ]
    let str = NSAttributedString(string: emoji, attributes: attrs)
    let s = str.size()
    let origin = NSPoint(x: (px - s.width) / 2, y: (px - s.height) / 2)
    str.draw(at: origin)
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bmp = NSBitmapImageRep(data: tiff),
          let png = bmp.representation(using: .png, properties: [:]) else {
        fatalError("failed to render size \(size)")
    }
    return png
}

// Write all needed raw sizes.
var written: [Int: URL] = [:]
for s in sizes {
    let url = iconset.appendingPathComponent("raw_\(s).png")
    try render(size: s).write(to: url)
    written[s] = url
    print("rendered \(s)x\(s)")
}

// Symlink/copy to the @1x/@2x names iconutil expects.
// iconset convention: icon_<N>x<N>.png and icon_<N>x<N>@2x.png
let pairs: [(label: String, size: Int)] = [
    ("16x16",    16), ("16x16@2x", 32),
    ("32x32",    32), ("32x32@2x", 64),
    ("128x128", 128), ("128x128@2x", 256),
    ("256x256", 256), ("256x256@2x", 512),
    ("512x512", 512), ("512x512@2x", 1024),
]
for p in pairs {
    let src = written[p.size]!
    let dst = iconset.appendingPathComponent("icon_\(p.label).png")
    try? fm.removeItem(at: dst)
    try fm.copyItem(at: src, to: dst)
}

// Clean up raw_*.png (iconutil errors on unexpected files).
for url in written.values {
    try? fm.removeItem(at: url)
}

let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", "-o", outIcns.path, iconset.path]
try task.run()
task.waitUntilExit()
if task.terminationStatus != 0 {
    fatalError("iconutil failed (\(task.terminationStatus))")
}
print("wrote \(outIcns.path)")
