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

Load as unpacked extension:
- Vivaldi: `vivaldi://extensions`
- Chrome: `chrome://extensions`

This is the pragmatic path for a personal self-hosted tool — no Chrome Web Store review needed.

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
| `/api/credentials` | POST | `{ name, username, password, url, note }` | `{ id, name }` |

**Password is never returned by `GET /api/credentials`** — only metadata (name, username, url). This keeps credential exposure minimal.

All responses are JSON. All endpoints require `Authorization: Bearer <token>` except `POST /api/sessions`.

### Rails implementation notes

- New namespace: `app/controllers/api/`
- `Api::BaseController`: reads and validates Bearer token, sets `current_user`
- `Api::SessionsController`: create/destroy
- `Api::CredentialsController`: index (filtered by domain via `url` field), create
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

- **HTTPS is mandatory.** Without TLS, tokens are exposed in transit. Document self-signed cert setup for Raspberry Pi / LAN deployment (mkcert or Caddy auto-HTTPS).
- **CORS:** whitelist only `chrome-extension://<extension-id>`. Note: the extension ID changes on every unpacked reload — document the update step.
- **Rate-limit** `POST /api/sessions` to prevent brute-force (e.g. `rack-attack`, 5 req/min per IP).
- **Token rotation:** not implemented in v1; acceptable for personal use.
- **No auto-submit:** the content script fills fields only — the user always clicks Submit themselves.

---

## Known limitations

| Limitation | Notes |
|---|---|
| No offline support | Extension needs the Rails app reachable on the network |
| HTTP-only deployments | Token in `chrome.storage.local` is safe, but transit is not — HTTPS is required |
| Extension ID changes on unpacked reload | CORS config must be updated each time |
| No Firefox support | MV3 divergence makes cross-browser support non-trivial; out of scope |
| No password retrieval via extension | `GET /api/credentials` returns metadata only; a separate reveal endpoint can be added later |

---

## What this ADR does NOT cover

- Implementation of the API token feature — tracked as a separate issue (blocked by this ADR)
- HTTPS/TLS setup for the Raspberry Pi deployment — tracked separately
- Extension UI design details
