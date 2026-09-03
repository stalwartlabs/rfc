# MTA Hooks BoF deck

Slidev deck for the MTA Hooks BoF proposal, IETF 127.

    npm install
    npm run dev      # http://localhost:3030
    npm run export   # writes mta-hooks-bof.pdf

Styling mirrors the Stalwart website token set (`styles/tokens.css`),
so the deck inherits the same palette and typography. Diagrams are
plain HTML using the classes in `style.css` (`.rail`, `.lanes`,
`.cards`, `.flow`, `.strip`), so the deck has no component
dependencies and exports cleanly to PDF. No animations: `transition`
is `none` and the deck uses no click steps.

PDF export needs `playwright-chromium`, which is a devDependency; on a
fresh machine run `npx playwright install chromium` once.
