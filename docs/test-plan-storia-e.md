# Test Plan — Storia E: Content Script (capture + save prompt)

## Setup

1. Avviare Rails: `bin/dev-local` (o equivalente locale)
2. Avere un account utente esistente nel password manager
3. Aprire `vivaldi://extensions` (o `chrome://extensions`), attivare "Modalità sviluppatore"
4. Caricare l'extension come unpacked dalla cartella `extension/`
5. Leggere l'ID extension da `chrome://extensions`
6. Aggiungere `EXTENSION_ID=<id-letto>` in `bin/dev-local` e riavviare Rails
7. Verificare che nessun errore appaia nella console del service worker (`Ispeziona → background.js`)

---

## TC-01 — Nessun campo password nella pagina

**Precondizione:** Extension caricata e attiva.  
**Azione:** Aprire una pagina senza `<input type="password">` (es. `about:blank` o una pagina statica).  
**Atteso:** Nessun banner, nessun errore in console.

---

## TC-02 — Campo password rilevato al caricamento

**Precondizione:** Extension attiva.  
**Azione:** Aprire una pagina con un form login statico (es. `http://localhost:3000/login`).  
**Atteso:** Nessun banner — il banner compare SOLO dopo il submit. Nessun errore in console.

---

## TC-03 — Intercettazione submit, banner mostrato

**Precondizione:** Aprire `http://localhost:3000/login`.  
**Azione:** Compilare username e password, cliccare "Accedi".  
**Atteso:**
- Il submit del form viene temporaneamente bloccato
- Appare il banner in cima alla pagina con testo "Salva `<username>` nel password manager?"
- Il banner ha due bottoni: "Salva" e "Ignora"

---

## TC-04 — Conferma salvataggio

**Precondizione:** Banner visibile dopo submit (TC-03).  
**Azione:** Cliccare "Salva".  
**Atteso:**
- Il banner scompare
- La console del service worker (`chrome://extensions → Inspect → background.js`) mostra il log `[PM background] SAVE_CREDENTIAL ricevuto` con `username` e `url` corretti
- Il form procede al submit normalmente (pagina naviga o risponde come previsto)

---

## TC-05 — Rifiuto salvataggio

**Precondizione:** Banner visibile dopo submit (TC-03).  
**Azione:** Cliccare "Ignora".  
**Atteso:**
- Il banner scompare
- Nessun messaggio nella console del service worker
- Il form procede al submit normalmente

---

## TC-06 — Pagina senza campo username

**Precondizione:** Extension attiva.  
**Azione:** Aprire una pagina con solo `<input type="password">` (nessun campo testo/email), compilare e fare submit.  
**Atteso:** Banner compare con username vuoto o omesso; il flusso save/ignore funziona normalmente.

---

## TC-07 — SPA: campo password aggiunto dinamicamente

**Precondizione:** Extension attiva.  
**Azione:** Aprire una SPA che renderizza il form login dopo un'interazione (es. click su "Login"). Compilare e fare submit.  
**Atteso:** Identico a TC-03 — il MutationObserver rileva il campo aggiunto dopo il caricamento.

---

## TC-08 — Nessun doppio banner su submit multipli

**Precondizione:** Extension attiva su pagina con form login.  
**Azione:** Fare submit, lasciare il banner aperto, fare un secondo submit (se la pagina lo consente).  
**Atteso:** Un solo banner visibile alla volta — il secondo sostituisce il primo.

---

## TC-09 — Reload extension, nessun errore

**Precondizione:** Extension caricata.  
**Azione:** In `chrome://extensions`, cliccare il pulsante di reload dell'extension.  
**Atteso:** Nessun errore nel service worker inspector dopo il reload.
