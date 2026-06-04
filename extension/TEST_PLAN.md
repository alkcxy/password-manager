# Test Plan — Background Service Worker (Storia F)

Questo documento va committato nello stesso commit del codice produttivo.
Ogni test va eseguito almeno una volta sull'ambiente reale prima di considerare la storia "done".

## Setup comune

1. Aprire `chrome://extensions`, abilitare "Modalità sviluppatore".
2. Caricare la cartella `extension/` con "Carica estensione non pacchettizzata".
3. Aprire il DevTools del service worker: `chrome://extensions` → link "Service Worker" sotto il nome dell'estensione.
4. Avere il server Rails raggiungibile (es. `http://localhost:3000`) con almeno un utente registrato e alcune credenziali salvate.

**Helper console** (eseguire nel DevTools del service worker):

```js
// Settare baseUrl
await chrome.storage.sync.set({ baseUrl: 'http://localhost:3000' });

// Settare token valido (sostituire il valore reale dopo LOGIN)
await chrome.storage.local.set({ authToken: { token: 'TOKEN', expiresAt: Date.now() + 3600000 } });

// Settare token già scaduto
await chrome.storage.local.set({ authToken: { token: 'TOKEN', expiresAt: Date.now() - 1000 } });

// Rimuovere token
await chrome.storage.local.remove('authToken');

// Rimuovere baseUrl
await chrome.storage.sync.remove('baseUrl');

// Leggere stato storage
console.log(await chrome.storage.local.get(null));
console.log(await chrome.storage.sync.get(null));
```

---

## T01 — LOGIN happy path

**Precondizione:** `baseUrl` configurata; nessun `authToken` in storage.

**Azione:**
```js
await handleMessage({ type: 'LOGIN', payload: { email: 'user@example.com', password: 'password' } });
```

**Atteso:**
- Risposta `{ status: 'ok', data: { token: '...', expires_at: '...' } }`
- `chrome.storage.local` contiene `authToken = { token: '...', expiresAt: <ms nel futuro> }`

**Verifica storage:**
```js
await chrome.storage.local.get('authToken');
// → { authToken: { token: '...', expiresAt: <numero > Date.now()> } }
```

---

## T02 — LOGIN credenziali errate

**Precondizione:** `baseUrl` configurata.

**Azione:**
```js
await handleMessage({ type: 'LOGIN', payload: { email: 'wrong@example.com', password: 'wrong' } });
```

**Atteso:**
- Risposta `{ status: 'error', message: '...' }` (non TOKEN_EXPIRED)
- `chrome.storage.local` non contiene `authToken` (o il valore precedente è invariato)

---

## T03 — NOT_CONFIGURED (baseUrl assente)

**Precondizione:** rimuovere `baseUrl` da storage (`await chrome.storage.sync.remove('baseUrl')`).

**Azione (ripetere per ogni tipo di messaggio):**
```js
await handleMessage({ type: 'LOGIN', payload: { email: 'u', password: 'p' } });
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'example.com' } });
await handleMessage({ type: 'SAVE_CREDENTIAL', payload: { name: 'x', username: 'u', password: 'p', url: 'https://x.com' } });
```

**Atteso per ogni chiamata:**
- Risposta `{ status: 'NOT_CONFIGURED' }`
- Nessuna richiesta HTTP visibile nel tab Network del DevTools

---

## T04 — TOKEN_EXPIRED (token assente)

**Precondizione:** `baseUrl` configurata; rimuovere `authToken` (`await chrome.storage.local.remove('authToken')`).

**Azione:**
```js
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'example.com' } });
```

**Atteso:**
- Risposta `{ status: 'TOKEN_EXPIRED' }`
- Nessuna richiesta HTTP al server (tab Network del DevTools: nessuna chiamata a `/api/credentials`)

---

## T05 — TOKEN_EXPIRED (token scaduto localmente)

**Precondizione:** `baseUrl` configurata; impostare token scaduto:
```js
await chrome.storage.local.set({ authToken: { token: 'vecchio-token', expiresAt: Date.now() - 1000 } });
```

**Azione (ripetere per ogni tipo di messaggio autenticato):**
```js
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'example.com' } });
await handleMessage({ type: 'GET_CREDENTIAL', payload: { id: 1 } });
await handleMessage({ type: 'SAVE_CREDENTIAL', payload: { name: 'x', username: 'u', password: 'p', url: 'https://x.com' } });
await handleMessage({ type: 'LOGOUT' });
```

**Atteso per ogni chiamata:**
- Risposta `{ status: 'TOKEN_EXPIRED' }`
- Nessuna richiesta HTTP al server

---

## T06 — TOKEN_EXPIRED (401 dal server, token valido localmente)

**Precondizione:** `baseUrl` configurata; impostare in storage un token con `expiresAt` nel futuro ma non valido lato server:
```js
await chrome.storage.local.set({ authToken: { token: 'token-invalido-server', expiresAt: Date.now() + 3600000 } });
```

**Azione:**
```js
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'example.com' } });
```

**Atteso:**
- Il service worker fa la richiesta HTTP (token sembra valido localmente)
- Il server risponde 401
- Risposta al mittente: `{ status: 'TOKEN_EXPIRED' }`

---

## T07 — GET_CREDENTIALS happy path

**Precondizione:** `baseUrl` configurata; eseguire T01 per ottenere token valido; esistono credenziali per il dominio.

**Azione:**
```js
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'github.com' } });
```

**Atteso:**
- Risposta `{ status: 'ok', data: [ { id: ..., name: '...', username: '...', url: '...' }, ... ] }`
- Il campo `password` NON è presente negli oggetti della lista (è escluso dall'endpoint `GET /api/credentials`)

---

## T08 — GET_CREDENTIAL happy path (con password)

**Precondizione:** `baseUrl` configurata; token valido; conoscere l'`id` di una credenziale esistente (ricavabile da T07).

**Azione:**
```js
await handleMessage({ type: 'GET_CREDENTIAL', payload: { id: <id_valido> } });
```

**Atteso:**
- Risposta `{ status: 'ok', data: { id: ..., name: '...', username: '...', url: '...', password: '...', note: '...' } }`
- Il campo `password` è presente e valorizzato (questo è il valore aggiunto di GET_CREDENTIAL rispetto a GET_CREDENTIALS)

---

## T09 — SAVE_CREDENTIAL happy path

**Precondizione:** `baseUrl` configurata; token valido.

**Azione:**
```js
await handleMessage({ type: 'SAVE_CREDENTIAL', payload: { name: 'Test Site', username: 'testuser', password: 'testpass', url: 'https://test.example.com' } });
```

**Atteso:**
- Risposta `{ status: 'ok', data: { id: ..., name: 'Test Site' } }`
- Side effect: la credenziale appare in una successiva chiamata GET_CREDENTIALS con dominio `test.example.com`

**Verifica side effect:**
```js
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'test.example.com' } });
// → la lista include la credenziale appena salvata
```

---

## T10 — LOGOUT happy path

**Precondizione:** `baseUrl` configurata; token valido in storage.

**Azione:**
```js
await handleMessage({ type: 'LOGOUT' });
```

**Atteso:**
- Risposta di successo (es. `{ status: 'ok' }`)
- `chrome.storage.local` non contiene più `authToken` (o è `null`/`undefined`)

**Verifica storage:**
```js
await chrome.storage.local.get('authToken');
// → { authToken: undefined } oppure {}
```

**Verifica che le successive richieste autenticate falliscano:**
```js
await handleMessage({ type: 'GET_CREDENTIALS', payload: { domain: 'example.com' } });
// → { status: 'TOKEN_EXPIRED' }
```

---

## T11 — Messaggio sconosciuto

**Azione:**
```js
await handleMessage({ type: 'TIPO_INESISTENTE' });
```

**Atteso:**
- Risposta `{ status: 'error', message: 'Unknown message type' }`

---

## T12 — Flusso completo end-to-end

Simulare l'intero ciclo di vita come farebbe il popup:

1. Inviare LOGIN → token salvato
2. Inviare GET_CREDENTIALS con dominio → lista ricevuta
3. Inviare GET_CREDENTIAL con id dalla lista → oggetto con `password` ricevuto
4. Inviare SAVE_CREDENTIAL → credenziale salvata
5. Inviare LOGOUT → token rimosso
6. Inviare GET_CREDENTIALS → risposta `TOKEN_EXPIRED`

Tutti e 6 gli step devono produrre il risultato atteso in sequenza.
