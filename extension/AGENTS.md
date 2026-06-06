# Browser extension

Chrome extension (Manifest V3, plain JS — no bundler/build step) that autofills credentials from the password-manager server into web pages.

## Architecture

- `manifest.json` — MV3 manifest: permissions (`storage`, `tabs`, `<all_urls>`), content scripts, service worker
- `background.js` — service worker: holds `authToken` (in `chrome.storage.local`) and `baseUrl` (in `chrome.storage.sync`), talks to the Rails API
- `content_script.js` — injected into pages: detects login forms, autofills, shows the auth banner
- `install_marker.js` — runs at `document_start`, marks the page as having the extension installed
- `popup.js` / `popup.html` — toolbar popup UI (login, credential list/search, save/edit)
- `options.js` / `options.html` — settings page (server `baseUrl`, etc.)

## Manual testing — no automated test suite here

This extension has **no unit/integration tests**. Verification is done through **`TEST_PLAN*.md`** documents:

- Each plan must be **committed in the same commit as the production code** it covers
- Each test case must be **run at least once against the real environment** (loaded extension + running Rails server) before the story can be considered done
- `TEST_PLAN.md` is the main plan; `TEST_PLAN_<topic>.md` files cover specific features/regressions (e.g. `TEST_PLAN_popup.md`, `TEST_PLAN_banner_no_duplicate.md`)

When changing extension behavior, update or add the relevant `TEST_PLAN*.md` rather than writing Rails/Minitest tests for it.

### Loading the extension for manual testing

1. `chrome://extensions` → enable "Developer mode"
2. "Load unpacked" → select the `extension/` folder
3. For the service worker: `chrome://extensions` → "Service Worker" link under the extension name (opens DevTools where you can inspect/seed `chrome.storage`)
4. Have the Rails server reachable (e.g. `http://localhost:3000`) with a registered user and some saved credentials

See the `## Setup comune` section of `TEST_PLAN.md` for ready-to-paste DevTools console snippets to seed/inspect `chrome.storage.sync` / `chrome.storage.local`.
