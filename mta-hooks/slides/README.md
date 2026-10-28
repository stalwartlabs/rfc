# MTA Hooks BoF deck

Slidev deck for the MTA Hooks BoF proposal, IETF 127. It presents
draft-degennaro-mta-hooks-02.

    npm install
    npm run dev      # http://localhost:3030
    npm run build    # static site in dist/
    npm run export   # writes mta-hooks-bof.pdf

Styling follows the bento look of the Stalwart website: the light
token set from `src/styles/tokens.css` is mirrored in
`styles/tokens.css`, and the tile, tray, pill and chip primitives from
`src/styles/primitives.css` are reproduced in `style.css` (`.bento`,
`.tile`, `.tile--sand`, `.tile--rose`, `.tile--ink`, `.tile--code`,
`.pill`, `.chip`, `.note`, `.rail`, `.section`). Fonts are Plus
Jakarta Sans (headings), Inter (body) and JetBrains Mono (code), all
bundled through `@fontsource-variable`, so the deck needs no network
access. Code blocks use a small ink theme defined in `setup/shiki.ts`.

The deck forces the light color scheme. There are no animations:
`transition` is `none` and the deck uses no click steps.

PDF export needs `playwright-chromium`, which is a devDependency; on a
fresh machine run `npx playwright install chromium` once.

The deck is published at rfc.stalw.art/mta-hooks/slides through
GitHub Pages, which serves the repository as is. After changing the
slides, run `npm run site` to rebuild `index.html`, `404.html` and
`assets/` in this directory, and commit them.
