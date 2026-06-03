# Piano — Storia G: Options Page (#68)

**Branch:** `feature/options-page-story-g`  
**Issue:** https://github.com/alkcxy/password-manager/issues/68  
**Dipende da:** nessuna  
**Blocca:** #66 (background service worker), #67 (popup)

---

## Cosa dice l'issue vs ADR

L'ADR dice solo "options page, URL base in `chrome.storage.sync`". L'issue aggiunge:
- Validare che sia **HTTPS** (non solo URL valida)
- Feedback visivo al salvataggio
- Il background service worker leggerà da `chrome.storage.sync` ad ogni chiamata API

---

## File da creare/modificare

| File | Azione |
|---|---|
| `extension/options.html` | creare |
| `extension/options.js` | creare |
| `extension/manifest.json` | aggiungere `options_ui` |

---

## Prerequisiti verificati

| Prerequisito | Stato |
|---|---|
| Permesso `storage` nel manifest | ✅ già presente |
| `chrome.storage.sync` (API) | ✅ disponibile |
| `options_ui` nel manifest | da aggiungere |

---

## Comportamento atteso

- Form con un campo "URL della tua istanza" (es. `https://pm.example.com`)
- Validazione: URL valida **e** schema HTTPS
- Salvataggio in `chrome.storage.sync` alla conferma
- Feedback visivo al salvataggio (es. messaggio "Salvato")
- Al riapertura della options page, il campo mostra il valore già salvato

---

## Test plan manuale

1. Aprire la options page da `chrome://extensions` → "Dettagli" → "Opzioni"
2. Inserire URL HTTPS valida (es. `https://pm.example.com`) → salvare → riaprire → URL persiste
3. Inserire URL non HTTPS (es. `http://pm.example.com`) → deve mostrare errore
4. Inserire URL malformata (es. `not-a-url`) → deve mostrare errore
5. Salvare senza aver inserito nulla → errore o campo vuoto non salvato
6. Verificare valore in DevTools → Application → Storage → Extension Storage → Sync

---

## Note architetturali

- `chrome.storage.sync` sincronizza la preferenza tra dispositivi dello stesso account Chrome/Google
- La chiave da usare in storage: `baseUrl`
- JS puro, nessun build pipeline (coerente con l'ADR e il resto dell'extension)
- Dopo storia G, la storia F (background service worker) leggerà `baseUrl` da `chrome.storage.sync` ad ogni chiamata API
