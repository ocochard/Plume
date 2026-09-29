# Plume

Light macOS Markdown viewer: WKWebView + marked + mermaid. Live reload, HTML/PDF export, print.

    ./build.sh          # builds Plume.app (~3.6 MB, ad-hoc signed)
    open Plume.app      # or open a .md with it

Sources/Plume: AppKit shell. Resources: index.html, app.js, app.css, vendored marked, mermaid, github-markdown-css.
Icon: `swift tools/make-icon.swift && sh tools/make-icon.sh` regenerates Resources/Plume.icns.
Exports and print always use the light theme.

## Install

Download `Plume-<version>.zip` from Releases, unzip, drag `Plume.app` to `/Applications`.
Plume then appears in "Open With" for `.md` files. To make it the default: Get Info on a `.md`, choose Plume, Change All.

Plume is ad-hoc signed, not notarized (no Apple Developer ID). On first launch macOS blocks it:
System Settings > Privacy & Security > "Open Anyway", or

    xattr -dr com.apple.quarantine /Applications/Plume.app

Building from source avoids the block (needs Xcode Command Line Tools): `git clone`, `./build.sh`.

## Release

    ./release.sh        # build, Plume-<version>.zip + sha256

Version comes from `CFBundleShortVersionString` in `Info.plist`.

## License

BSD 2-Clause, see `LICENSE`. Vendored in `Resources/`, under their own MIT licenses:
marked, mermaid, github-markdown-css.
