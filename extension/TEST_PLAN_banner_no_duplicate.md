# Test Plan — Banner salvataggio: skip se credenziale già presente (Issue #85)

Questo documento va committato nello stesso commit del codice produttivo.
Ogni test va eseguito almeno una volta sull'ambiente reale prima di considerare la storia "done".

## Setup comune

1. Server Rails raggiungibile (es. `http://localhost:3000`).
2. Estensione caricata e configurata con `baseUrl` + utente autenticato.
3. Ricaricare l'estensione su `chrome://extensions` dopo ogni modifica al codice.

---

## T01 — Credenziale già presente: banner NON appare

**Precondizione:** esiste almeno una credenziale per il dominio del sito di test.

**Azione:** compilare e inviare un form di login su quel sito.

**Atteso:** dopo il redirect post-login, nessun banner appare.

---

## T02 — Nessuna credenziale per il dominio: banner salvataggio appare

**Precondizione:** nessuna credenziale salvata per il dominio del sito di test; utente autenticato nell'estensione.

**Azione:** compilare e inviare un form di login.

**Atteso:** dopo il redirect post-login, appare il banner "Salva `<username>` nel password manager?".

---

## T03 — Token scaduto: banner di login appare

**Precondizione:** token scaduto (`expiresAt` nel passato) o assente.

**Azione:** compilare e inviare un form di login su qualsiasi sito.

**Atteso:** appare il banner "Accedi all'estensione per salvare le credenziali su questo sito." con i pulsanti "Accedi" e "Ignora".

---

## T03a — Click "Accedi" su banner di login: popup si apre

**Precondizione:** banner di login visibile (da T03).

**Azione:** cliccare "Accedi".

**Atteso:** il banner scompare; il popup dell'estensione si apre.

---

## T03b — Click "Ignora" su banner di login: credenziale pendente cancellata

**Precondizione:** banner di login visibile (da T03).

**Azione:** cliccare "Ignora".

**Atteso:** il banner scompare; navigando di nuovo sullo stesso sito il banner non riappare (credenziale pendente cancellata).

---

## T04 — Estensione non configurata: banner di login appare

**Precondizione:** `baseUrl` non configurata (`await chrome.storage.sync.remove('baseUrl')`).

**Azione:** compilare e inviare un form di login.

**Atteso:** appare il banner "Accedi all'estensione per salvare le credenziali su questo sito." (stesso comportamento di T03).

---

## T05 — Salva da T02, poi rifare login: banner non appare più

**Precondizione:** T02 completato, credenziale salvata tramite il banner.

**Azione:** tornare sulla pagina di login e ripetere il login.

**Atteso:** nessun banner appare.

---

## T06 — Dopo login via banner di autenticazione: banner salvataggio riappare

**Precondizione:** T03 completato (banner di login mostrato, credenziale pendente ancora in storage); nessuna credenziale per il dominio.

**Azione:** cliccare "Accedi" → effettuare il login nel popup → navigare sulla pagina originale.

**Atteso:** appare il banner di salvataggio (la credenziale pendente è ancora in storage e ora l'utente è autenticato).
