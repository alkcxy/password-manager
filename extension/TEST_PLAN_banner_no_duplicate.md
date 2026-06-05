# Test Plan — Banner salvataggio: skip se credenziale già presente (Issue #85)

Questo documento va committato nello stesso commit del codice produttivo.
Ogni test va eseguito almeno una volta sull'ambiente reale prima di considerare la storia "done".

## Setup comune

1. Server Rails raggiungibile (es. `http://localhost:3000`).
2. Estensione caricata e configurata con `baseUrl` + utente autenticato.
3. Ricaricare l'estensione su `chrome://extensions` dopo ogni modifica al codice.

---

## T01 — Credenziale già presente: banner NON appare

**Precondizione:** esiste almeno una credenziale per il dominio del sito di test (es. `localhost`).

**Azione:** compilare e inviare un form di login su quel sito.

**Atteso:** dopo il redirect post-login, il banner "Salva nel password manager?" **non appare**.

---

## T02 — Nessuna credenziale per il dominio: banner appare

**Precondizione:** nessuna credenziale salvata per il dominio del sito di test.

**Azione:** compilare e inviare un form di login.

**Atteso:** dopo il redirect post-login, il banner **appare** con il messaggio "Salva `<username>` nel password manager?".

---

## T03 — Fail open: token scaduto → banner appare

**Precondizione:** token scaduto (`expiresAt` nel passato) o assente.

**Azione:** compilare e inviare un form di login su qualsiasi sito.

**Atteso:** il banner **appare** (fail open — la verifica delle credenziali fallisce silenziosamente).

---

## T04 — Fail open: estensione non configurata → banner appare

**Precondizione:** `baseUrl` non configurata (`await chrome.storage.sync.remove('baseUrl')`).

**Azione:** compilare e inviare un form di login.

**Atteso:** il banner **appare** (fail open).

---

## T05 — Salva da T02, poi rifare login: banner non appare più

**Precondizione:** T02 completato, credenziale salvata tramite il banner.

**Azione:** tornare sulla pagina di login e ripetere il login.

**Atteso:** il banner **non appare** — la credenziale è ora presente nel db.
