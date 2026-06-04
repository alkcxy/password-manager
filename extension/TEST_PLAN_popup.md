# Test Plan — Popup (Storia H)

Questo documento va committato nello stesso commit del codice produttivo.
Ogni test va eseguito almeno una volta sull'ambiente reale prima di considerare la storia "done".

## Stato "rosso" di partenza

Prima di implementare: cliccare l'icona dell'estensione → non succede niente (manca `"action"` nel manifest e `popup.html` non esiste). Questo è il fallimento verificabile.

## Setup comune

1. Caricare l'extension da un checkout che includa **sia F che H** (PR #75 mergiata + questo branch, oppure branch combinato).
2. Ricaricare l'extension ogni volta che si modificano i file (`chrome://extensions` → icona reload).
3. Server Rails su `http://localhost:3000` con seed eseguito (`rails db:seed`).
4. Credenziali seed disponibili: `dev@example.com` / `password`, con credenziali per GitHub (`github.com`), Gmail (`mail.google.com`), AWS (`aws.amazon.com`).

**Helper per pulire lo stato tra un test e l'altro** (DevTools del service worker):
```js
await chrome.storage.local.clear();
await chrome.storage.sync.remove('baseUrl');
```

---

## T01 — Popup si apre

**Precondizione:** extension caricata con il nuovo manifest (con `"action"`).

**Azione:** cliccare l'icona dell'extension nella toolbar di Chrome.

**Atteso:** si apre un popup (finestra dell'extension). Non importa ancora cosa mostra — basta che si apra.

---

## T02 — Vista login quando non autenticato

**Precondizione:** `baseUrl` configurata (`http://localhost:3000`); nessun `authToken` in storage.

**Azione:** aprire il popup.

**Atteso:**
- Il popup mostra un form con campi email e password
- Non mostra una lista di credenziali
- Non mostra errori

---

## T03 — NOT_CONFIGURED (baseUrl assente)

**Precondizione:** `await chrome.storage.sync.remove('baseUrl')`; nessun token.

**Azione:** aprire il popup.

**Atteso:** il popup mostra un messaggio che indica che l'istanza non è configurata (non un crash silenzioso, non la lista vuota).

---

## T04 — Login happy path → passa alla vista credenziali

**Precondizione:** `baseUrl` = `http://localhost:3000`; nessun token.

**Azione:**
1. Aprire il popup → compare form login
2. Inserire `dev@example.com` / `password`
3. Cliccare il bottone di login (o premere Enter)

**Atteso:**
- Il popup non mostra errori
- La vista si trasforma: scompaiono i campi email/password, compare la lista delle credenziali (o il messaggio "nessuna credenziale" se il dominio del tab corrente non ha match)
- `chrome.storage.local.get('authToken')` nel DevTools del SW → contiene un token con `expiresAt` nel futuro

---

## T05 — Login con credenziali errate → errore inline

**Precondizione:** `baseUrl` configurata; nessun token.

**Azione:**
1. Aprire il popup
2. Inserire email/password errate
3. Cliccare login

**Atteso:**
- Il popup mostra un messaggio di errore inline (es. "Credenziali non valide")
- Il form rimane visibile (non passa alla vista credenziali)
- `chrome.storage.local.get('authToken')` → nessun token salvato

---

## T06 — Lista credenziali per dominio corrente

**Precondizione:** autenticato (eseguire T04); aprire una tab su `https://github.com` (o qualsiasi pagina con dominio matching).

**Azione:** aprire il popup mentre la tab attiva è su `github.com`.

**Atteso:**
- Popup mostra almeno la credenziale "GitHub" con username `devuser`
- Ogni credenziale ha un bottone "Compila" (o equivalente)

---

## T07 — Nessuna credenziale per il dominio

**Precondizione:** autenticato; tab attiva su un dominio senza credenziali (es. `https://example.com`).

**Azione:** aprire il popup.

**Atteso:** popup mostra un messaggio tipo "Nessuna credenziale per questo sito" — non una lista vuota silenziosa.

---

## T08 — "Compila" riempie username e password nella pagina

**Precondizione:** autenticato; tab attiva su `http://localhost:3000/users/sign_in` (o qualsiasi pagina con form di login) con una credenziale matching in storage.

**Azione:**
1. Aprire il popup → credenziale matching mostrata
2. Cliccare "Compila" sulla credenziale

**Atteso:**
- Il campo email/username nella pagina viene riempito con il valore salvato
- Il campo password nella pagina viene riempito con la password (recuperata via `GET_CREDENTIAL`)
- Il popup si chiude (o rimane aperto — comportamento da verificare e documentare)

---

## T09 — Fill parziale (nessun campo username visibile)

**Precondizione:** autenticato; tab attiva su una pagina che mostra solo il campo password (es. step 2 di un login in due fasi come Google dopo aver inserito l'email).

**Azione:** aprire il popup → cliccare "Compila".

**Atteso:**
- Il campo password viene riempito
- Nessun errore visibile — fallback silenzioso sul campo username mancante

---

## T10 — Fill compatibilità SPA (React/Vue)

**Precondizione:** autenticato; tab attiva su un sito React/Vue con form di login e credenziale matching (es. `github.com`).

**Azione:** aprire il popup → cliccare "Compila".

**Atteso:**
- I campi vengono riempiti e il framework SPA "vede" il valore (cioè il form non rimane bloccato con i campi visivamente pieni ma logicamente vuoti)
- Verifica concreta: dopo il fill, cliccare "Submit" — il sito deve accettare il form (non mostrare "campo obbligatorio" o "password non valida" a causa di eventi mancanti)

---

## T11 — Picker con più credenziali

**Precondizione:** autenticato; tab attiva su un dominio che ha **due o più** credenziali salvate. Creare una seconda credenziale per lo stesso dominio via `POST /api/credentials` se necessario:
```bash
curl -s -X POST http://localhost:3000/api/credentials \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"GitHub Alt","username":"altuser","password":"altpass","url":"https://github.com"}'
```

**Azione:** aprire il popup su `github.com`.

**Atteso:**
- Il popup mostra entrambe le credenziali nella lista
- Cliccando "Compila" su ciascuna riempie con i dati di quella specifica credenziale (username diverso)

---

## T12 — TOKEN_EXPIRED dal server (token valido localmente, rifiutato dal server)

**Precondizione:** forzare in storage un token con `expiresAt` nel futuro ma valore non valido:
```js
await chrome.storage.local.set({ authToken: { token: 'invalido', expiresAt: Date.now() + 3600000 } });
```

**Azione:** aprire il popup.

**Atteso:**
- Il popup tenta `GET_CREDENTIALS`, il background riceve 401 dal server e risponde `TOKEN_EXPIRED`
- Il popup mostra la vista login (non la lista vuota, non un crash)

---

## T13 — Logout

**Precondizione:** autenticato (T04 completato).

**Azione:**
1. Aprire il popup → vista credenziali visibile
2. Cliccare il bottone logout

**Atteso:**
- Il popup mostra la vista login
- `chrome.storage.local.get('authToken')` → `authToken` assente o `null`
- Riaprendo il popup: mostra ancora la vista login (stato persistito)

---

## T14 — Token scaduto localmente → vista login senza chiamata HTTP

**Precondizione:** forzare token scaduto:
```js
await chrome.storage.local.set({ authToken: { token: 'vecchio', expiresAt: Date.now() - 1000 } });
```

**Azione:** aprire il popup.

**Atteso:**
- Mostra subito la vista login
- Nel tab Network del DevTools del service worker: nessuna richiesta HTTP a `/api/credentials`

---

## T15 — Flusso end-to-end completo

1. Storage pulito, `baseUrl` configurata
2. Aprire popup → vista login
3. Login con `dev@example.com` / `password` → vista credenziali su `github.com`
4. Cliccare "Compila" → campi riempiti nella pagina
5. Cliccare logout → vista login
6. Riaprire popup → ancora vista login
