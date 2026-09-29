# Plume

Light macOS Markdown viewer: WKWebView + marked + mermaid. Live reload, HTML/PDF export, print.

    ./build.sh          # builds Plume.app (~3.6 MB, ad-hoc signed)
    open Plume.app      # or open a .md with it

Sources/Plume: AppKit shell. Resources: index.html, app.js, app.css, vendored marked, mermaid, github-markdown-css.
Icon: `swift tools/make-icon.swift && sh tools/make-icon.sh` regenerates Resources/Plume.icns.
Exports and print always use the light theme.

## License

BSD 2-Clause, see `LICENSE`. Vendored in `Resources/`, under their own MIT licenses:
marked, mermaid, github-markdown-css.
