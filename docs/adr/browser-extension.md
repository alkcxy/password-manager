# ADR: Browser Extension for Auto-saving Passwords

**Status:** Accepted  
**Date:** 2026-06-02  
**Issue:** #51

---

## Context

The password manager is a self-hosted Rails 8 app (MongoDB, Hotwire) with session-based authentication. There is no existing API layer. The goal is to add a browser extension for Chrome and Vivaldi (both Chromium, both support Manifest V3) that can:

1. Capture credentials when the user logs in to a site and save them to this password manager
2. Auto-fill login forms from credentials stored in the password manager

---

## Architecture

### Extension components (Manifest V3)

| Component | Responsibility |
|---|---|
| **Content script** | Detect `<input type="password">`, intercept form `submit`, show a save prompt; use `MutationObserver` to handle SPAs that render fields after initial load |
| **Background service worker** | Call the Rails API, manage the auth token, handle token refresh |
| **Extension popup** | Show credentials matching the current domain, trigger fill, login/logout flow |

### Build tooling

Plain JavaScript + ES modules — no Node.js build pipeline. Consistent with the Rails app's import-map approach and avoids tooling overhead for a personal self-hosted tool. If the popup grows complex, a single `esbuild` step is acceptable.

### Distribution

Published on the Chrome Web Store ($5 one-time developer fee).

For development, load as unpacked extension:
- Vivaldi: `vivaldi://extensions`
- Chrome: `chrome://extensions`

### Stable extension ID (development + production)

The extension ID is derived deterministically from a keypair baked into `manifest.json`. This means the ID is stable across reloads and reinstalls — no need to update the CORS config each time, and no dependency on Chrome Web Store publication for a fixed ID.

Generate the keypair once:

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -nocrypt -out extension/key.pem
openssl rsa -in extension/key.pem -pubout -outform DER | base64 -w0
```

Add the Base64 output to `manifest.json`:

```json
"key": "<base64-encoded-public-key>"
```

The resulting ID (visible in `chrome://extensions` after loading unpacked) is set once in the Rails environment as `EXTENSION_ID` and never changes. The private key (`key.pem`) must be kept secret and excluded from version control.

**HTTP in development (localhost only)**: Chrome treats `localhost` as a secure context — the extension can call `http://localhost:3000` without HTTPS. No special setup needed when the browser and the Rails server are on the same machine.

**HTTP in development (LAN, server on a different machine)**: `http://192.168.x.x` is not a secure context — Chrome blocks requests from the extension to a plain HTTP LAN address. Use `mkcert` to issue a locally-trusted certificate for the LAN IP:

```bash
# install mkcert and its root CA (once per machine)
mkcert -install

# issue a cert for the LAN IP (replace with your actual IP)
mkcert 192.168.1.100
# produces: 192.168.1.100.pem  192.168.1.100-key.pem
```

Then start Puma with TLS:

```bash
bin/rails server -b "ssl://0.0.0.0:3000?key=192.168.1.100-key.pem&cert=192.168.1.100.pem"
```

The extension Options page should be set to `https://192.168.1.100:3000`. The mkcert root CA must be installed on every machine whose browser will connect (run `mkcert -install` there too).

### Configurable base URL

The extension must work with any self-hosted instance. The base URL of the Rails app (e.g. `https://pm.example.com`) is stored in `chrome.storage.sync` via an **Options page** and read by the background service worker on every API call. This is required for Chrome Web Store publication.

---

## Rails API additions required

The extension cannot use session cookies (cross-origin). A token-based auth layer must be added on top of the existing session auth.

A new `ApiToken` Mongoid model will store tokens: `token` (opaque, SecureRandom hex), `user_id`, `expires_at`, `created_at`.

### Endpoints

| Endpoint | Method | Request body | Response |
|---|---|---|---|
| `/api/sessions` | POST | `{ email, password }` | `{ token, expires_at }` |
| `/api/sessions/:token` | DELETE | — | `204 No Content` |
| `/api/credentials` | GET | `?domain=<host>` | `[{ id, name, username, url }]` |
| `/api/credentials/:id` | GET | — | `{ id, name, username, url, password, note }` |
| `/api/credentials` | POST | `{ name, username, password, url, note }` | `{ id, name }` |

**`GET /api/credentials` (list) never returns the password** — only metadata. The password is exposed only via `GET /api/credentials/:id` (single credential), used by the extension popup to autofill the password field.

All responses are JSON. All endpoints require `Authorization: Bearer <token>` except `POST /api/sessions`.

### Rails implementation notes

- New namespace: `app/controllers/api/`
- `Api::BaseController`: reads and validates Bearer token, sets `current_user`
- `Api::SessionsController`: create/destroy
- `Api::CredentialsController`: index (filtered by domain via `url` field), show (returns password for autofill), create
- CORS: add `rack-cors` gem, whitelist `chrome-extension://<extension-id>`
- No changes to existing web controllers

---

## Auth token lifecycle

```
Extension login
  → POST /api/sessions { email, password }
  ← { token, expires_at }
  → stored in chrome.storage.local

Per-request
  → Authorization: Bearer <token>
  ← 401 if expired or not found

Extension logout
  → DELETE /api/sessions/:token
  ← 204

Token expiry
  → 30-day TTL (configurable via env var API_TOKEN_TTL_DAYS)
  → Expired tokens are rejected; user must log in again
```

`chrome.storage.local` provides OS-level encryption on most platforms and is isolated per extension — preferable to `localStorage` which is accessible to page scripts.

---

## Security considerations

- **HTTPS assumed.** The app is deployed on a public domain under HTTPS — no self-signed cert setup needed.
- **CORS:** whitelist only `chrome-extension://<extension-id>`. The ID is stable because it is derived from the keypair in `manifest.json` — set `EXTENSION_ID` env var once, never touch it again.
- **Rate-limit** `POST /api/sessions` to prevent brute-force (e.g. `rack-attack`, 5 req/min per IP).
- **Token rotation:** not implemented in v1; acceptable for personal use.
- **No auto-submit:** the content script fills fields only — the user always clicks Submit themselves.

---

## Known limitations

| Limitation | Notes |
|---|---|
| No offline support | Extension needs the Rails app reachable on the network |
| No Firefox support | MV3 divergence makes cross-browser support non-trivial; out of scope |
| No password retrieval via extension | `GET /api/credentials` returns metadata only; use `GET /api/credentials/:id` to retrieve the password for autofill |
| Cross-origin iframes | Login forms embedded from a different domain (Auth0, Okta, Stripe) are inaccessible to the content script — hard browser limit |
| Shadow DOM | Form fields inside Shadow DOM components may not be reachable via standard `querySelector` |
| Non-standard SPA event handling | Some React/Vue apps require specific synthetic events to detect programmatically injected values; requires per-site testing |
| Username detection imprecisa | Su alcuni siti (es. Microsoft login) l'euristica DOM può catturare un campo sbagliato come username. I campi `name`, `username` e `url` sono tutti modificabili dall'utente al momento del salvataggio (storia H — popup). |

---

## Implementation roadmap

Le seguenti issue vanno lavorate in ordine — ogni step è prerequisito del successivo.

| # | Storia | Issue | Dipende da | Stato |
|---|---|---|---|---|
| A | ~~HTTPS/TLS setup~~ _(non necessario: dominio pubblico con HTTPS)_ | [#61](https://github.com/alkcxy/password-manager/issues/61) | — | ✅ |
| B | ~~Rails API layer: `ApiToken` model + `Api::BaseController` + token auth~~ | [#62](https://github.com/alkcxy/password-manager/issues/62) | — | ✅ |
| C | ~~Rails API: `Api::SessionsController` (login/logout) + `rack-attack`~~ | [#63](https://github.com/alkcxy/password-manager/issues/63) | B | ✅ |
| D | ~~Rails API: `Api::CredentialsController` (index per domain, create) + `rack-cors`~~ | [#64](https://github.com/alkcxy/password-manager/issues/64) | B | ✅ |
| E | ~~Browser extension: content script (capture + save prompt)~~ ¹ | [#65](https://github.com/alkcxy/password-manager/issues/65) | C, D | ✅ (patch pendente dopo F+H) |
| G | ~~Browser extension: options page (URL base configurabile, salvataggio in `chrome.storage.sync`)~~ | [#68](https://github.com/alkcxy/password-manager/issues/68) | — | ✅ |
| F+H | Browser extension: background service worker + popup (login/logout, credential list, fill) | [#66](https://github.com/alkcxy/password-manager/issues/66) [#67](https://github.com/alkcxy/password-manager/issues/67) | C, D, E, G | 🔶 PR #76 aperta — da testare |
| I | Web app: banner/suggerimento installazione extension | [#69](https://github.com/alkcxy/password-manager/issues/69) | — | ⬜ da fare |
| J | ~~`.dockerignore`: escludere `extension/` e `docs/` dall'immagine Docker~~ | — | — | ✅ |

**Note:**

¹ **E — patch pendente:** il content script invia `SAVE_CREDENTIAL` senza gestire la risposta del background. Se l'utente non è autenticato o la `baseUrl` non è configurata, il salvataggio fallisce silenziosamente. Dopo il merge di F+H, E va aggiornato per mostrare un feedback all'utente in caso di `TOKEN_EXPIRED` o `NOT_CONFIGURED`.

**Taglio sbagliato — lezione appresa:** F (background SW) e H (popup) erano state definite come storie separate con F prerequisito di H. In pratica il background senza popup non porta nessun valore osservabile: nessuna UI per il login, `SAVE_CREDENTIAL` dal content script fallisce silenziosamente, niente da testare end-to-end. Il taglio corretto era una storia unica "extension lato client" oppure due storie con ordine inverso (popup prima, che guida il design del background). Le due issue sono state collassate in un'unica PR (#76).

---

## Implementation notes (storia E)

Scoperte durante l'implementazione del content script:

- **`chrome.storage.session` non disponibile nei content script** (almeno su Vivaldi): si usa `chrome.storage.local` con cleanup immediato dopo l'uso.
- **`MutationObserver` su `document.documentElement`**, non su `document.body`: Turbo Drive sostituisce `document.body` ad ogni navigazione, rendendo inutile un observer attaccato al vecchio body.
- **SPA senza `<form>`** (es. Authelia/MUI): il submit avviene via `fetch` senza evento `submit`. Il content script trova il bottone di submit per posizione nel DOM (`compareDocumentPosition`) invece che per `type="submit"`.
- **Login in due fasi** (es. Microsoft, Google): username e password sono su pagine separate. Il content script salva il username in `pendingUsername` (memoria + `chrome.storage.local`) durante la fase 1 e lo consuma durante la fase 2.
- **Rilevamento successo login rimosso**: l'estensione non può sapere se il login è andato a buon fine senza conoscere la logica del sito. Il banner compare sempre dopo ogni navigazione post-submit; l'utente decide se salvare.

---

## What this ADR does NOT cover

- Firefox support (MV3 divergence, out of scope)
- Extension UI design details beyond the functional requirements above
