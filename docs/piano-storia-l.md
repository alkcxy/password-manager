# Piano Storia L — Form review/modifica credenziale (overlay in-page)

**Issue principale:** #79 — Popup: form review/modifica credenziale dopo salvataggio o errore di validazione  
**Prerequisito:** #81 — `PUT /api/credentials/:id`  
**Branch:** `feature/story-l-popup-review-form`

---

## 1. Cosa dice l'issue (vs ADR)

Nessun ADR collegato. L'issue è esaustiva:

- Mostrare un form di review **prima** del salvataggio, con campi `name`, `username`, `password`, `url` pre-compilati dai dati catturati dal content script e modificabili dall'utente.
- Dopo un errore 422: tenere il form aperto con i messaggi di errore inline.
- Dopo un salvataggio riuscito (201): mostrare conferma e chiudere l'overlay.
- Usare `PUT /api/credentials/:id` (issue #81) per permettere la modifica di una credenziale già salvata.

**Scelta architetturale:** il form è un **overlay iniettato nel DOM della pagina dal content script** (Opzione A), stesso pattern del banner attuale. Non tocca popup.html/popup.js. Motivazione: funziona su tutte le versioni Chrome, nessun problema di `openPopup()`, flusso continuo senza click extra sull'icona.

---

## 2. Ambiente

Ruby 3.3.11 + Rails disponibili natively.  
Docker non disponibile.  
Test backend: `rails test test/controllers/api/credentials_controller_test.rb`

---

## 3. Verifiche di config eseguite

- `config/routes.rb` namespace `api`: `resources :credentials, only: [:index, :show, :create]` → manca `:update`, da aggiungere.
- `credential_params` nel controller già permette `name, username, password, url, note` → riutilizzabile per `update` senza modifiche.
- `serialize_summary` già restituisce `{ id, name }` → compatibile con la spec 200 di #81.
- `manifest.json` — nessun permesso nuovo necessario.
- `BANNER_ID = 'pm-save-banner'` già usato nel content script; l'overlay review userà un ID diverso (`pm-review-form`).

---

## 4. Prerequisiti tecnici

| Prerequisito | Piano |
|---|---|
| PUT endpoint (#81) | Step A — backend TDD |
| Handler `UPDATE_CREDENTIAL` in background + gestione 422 in `apiFetch` | Step B |
| Overlay review form nel content script | Step C |
| Banner "Salva" apre overlay (non chiama più `SAVE_CREDENTIAL` direttamente) | Step C (stesso step) |

---

## 5. Strategia di test

**Backend (automatica, TDD):**  
Aggiungere i test **prima** dell'implementazione in `test/controllers/api/credentials_controller_test.rb`:
- PUT senza token → 401
- PUT valido → 200 `{ id, name }`
- PUT campo mancante → 422 `{ errors: [...] }`
- PUT su credenziale altro utente → 404

**Extension (manuale):** test plan strutturato in sezione 7.

---

## 6. Passi di implementazione

### Step A — Backend: PUT /api/credentials/:id (issue #81)

**TDD — test prima, codice dopo.**

1. **`test/controllers/api/credentials_controller_test.rb`** — aggiungere sezione `# PUT /api/credentials/:id`:

   ```ruby
   test "update returns 401 without token" do
     put "/api/credentials/#{@github_cred.id}",
         params: { name: "GitHub Updated", username: "alice", password: "newpass", url: "https://github.com" },
         as: :json
     assert_response :unauthorized
   end

   test "update returns 200 with valid params" do
     put "/api/credentials/#{@github_cred.id}",
         params: { name: "GitHub Updated", username: "alice2", password: "newpass", url: "https://github.com" },
         headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
     assert_response :ok
     json = JSON.parse(response.body)
     assert_equal @github_cred.id.to_s, json["id"]
     assert_equal "GitHub Updated", json["name"]
     assert_nil json["password"]
   end

   test "update returns 422 when required param missing" do
     put "/api/credentials/#{@github_cred.id}",
         params: { name: "", username: "alice", password: "pass", url: "https://github.com" },
         headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
     assert_response :unprocessable_entity
     json = JSON.parse(response.body)
     assert json["errors"].present?
   end

   test "update returns 404 for another user credential" do
     put "/api/credentials/#{@other_cred.id}",
         params: { name: "Hack", username: "alice", password: "pass", url: "https://github.com" },
         headers: { "Authorization" => "Bearer #{@token.token}" }, as: :json
     assert_response :not_found
   end
   ```

2. **`config/routes.rb`** — aggiungere `:update`:
   ```ruby
   resources :credentials, only: [:index, :show, :create, :update]
   ```

3. **`app/controllers/api/credentials_controller.rb`** — aggiungere `update`:
   ```ruby
   def update
     credential = @current_user.credentials.find(params[:id])
     if credential.update(credential_params)
       render json: { id: credential.id.to_s, name: credential.name }
     else
       render json: { errors: credential.errors.full_messages }, status: :unprocessable_entity
     end
   rescue Mongoid::Errors::DocumentNotFound
     render json: { error: "Credential not found" }, status: :not_found
   end
   ```

---

### Step B — background.js: UPDATE_CREDENTIAL + fix 422 in apiFetch

1. Aggiungere case al switch:
   ```js
   case 'UPDATE_CREDENTIAL': return updateCredential(message.payload);
   ```

2. Aggiungere funzione:
   ```js
   async function updateCredential({ id, name, username, password, url, note }) {
     const authResult = await resolveAuth();
     if (authResult.error) return authResult.error;
     const { baseUrl, token } = authResult;
     return apiFetch(`${baseUrl}/api/credentials/${encodeURIComponent(id)}`, {
       method: 'PUT',
       headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
       body: JSON.stringify({ name, username, password, url, note }),
     });
   }
   ```

3. Adattare `apiFetch` per 422 (attualmente restituisce `status: 'error', message: <testo grezzo>`):
   ```js
   if (response.status === 422) {
     const data = await response.json().catch(() => ({}));
     return { status: 'error', errors: data.errors || ['Errore di validazione'] };
   }
   ```

---

### Step C — content_script.js: overlay review form

Il content script già inietta il banner nel DOM. Il review form è un overlay più ricco con lo stesso approccio.

**Costanti da aggiungere:**
```js
const REVIEW_ID = 'pm-review-form';
```

**Funzione `removeReviewForm()`:**
```js
function removeReviewForm() {
  const el = document.getElementById(REVIEW_ID);
  if (el) el.remove();
}
```

**Funzione `showReviewForm(cred)`** — inietta l'overlay nel DOM:

```js
function showReviewForm(cred) {
  removeReviewForm();
  removeBanner();

  const overlay = document.createElement('div');
  overlay.id = REVIEW_ID;
  // reset CSS per evitare interferenze con la pagina
  overlay.style.cssText =
    'all:initial;position:fixed;top:0;left:0;right:0;bottom:0;z-index:2147483647;' +
    'display:flex;align-items:center;justify-content:center;' +
    'background:rgba(0,0,0,0.45);font-family:system-ui,sans-serif';

  const box = document.createElement('div');
  box.style.cssText =
    'all:initial;background:#fff;border-radius:8px;padding:24px;width:340px;' +
    'box-shadow:0 4px 24px rgba(0,0,0,0.25);font-family:system-ui,sans-serif;font-size:14px;color:#1e293b';

  // costruisci i campi con helper makeField
  // ...

  overlay.appendChild(box);
  document.body.appendChild(overlay);
}
```

Struttura del box:
- Titolo `<h2>` "Salva credenziale"
- `<div id="pm-review-errors">` per errori inline (rosso, nascosto di default)
- 4 campi label+input: Nome, Username, Password (type=password), URL
- Riga bottoni: "Salva" (blu) + "Annulla" (trasparente)

**Handler Salva:**
```js
async function handleReviewSave(cred, saveBtn, errorDiv, fields) {
  saveBtn.disabled = true;
  errorDiv.style.display = 'none';
  const payload = {
    name: fields.name.value.trim(),
    username: fields.username.value.trim(),
    password: fields.password.value,
    url: fields.url.value.trim(),
  };
  const messageType = cred.id ? 'UPDATE_CREDENTIAL' : 'SAVE_CREDENTIAL';
  if (cred.id) payload.id = cred.id;

  let response;
  try {
    response = await chrome.runtime.sendMessage({ type: messageType, payload });
  } catch (_) {
    saveBtn.disabled = false;
    errorDiv.textContent = 'Errore di comunicazione con il background.';
    errorDiv.style.display = 'block';
    return;
  }

  if (response.status === 'ok') {
    clearPending();
    removeReviewForm();
    // breve banner di conferma
    showConfirmBanner(`"${payload.name}" salvata.`);
  } else if (response.status === 'error' && response.errors) {
    saveBtn.disabled = false;
    errorDiv.textContent = response.errors.join(' — ');
    errorDiv.style.display = 'block';
  } else if (response.status === 'TOKEN_EXPIRED') {
    clearPending();
    removeReviewForm();
    showAuthBanner();
  } else {
    saveBtn.disabled = false;
    errorDiv.textContent = 'Errore nel salvataggio. Riprova.';
    errorDiv.style.display = 'block';
  }
}
```

**`showConfirmBanner(msg)`** — banner verde temporaneo (3s):
```js
function showConfirmBanner(msg) {
  removeBanner();
  const banner = document.createElement('div');
  banner.id = BANNER_ID;
  banner.style.cssText =
    'position:fixed;top:0;left:0;right:0;z-index:2147483647;' +
    'background:#16a34a;color:#fff;padding:12px 16px;' +
    'font-family:system-ui,sans-serif;font-size:14px;text-align:center;' +
    'box-shadow:0 2px 8px rgba(0,0,0,0.35)';
  banner.textContent = msg;
  document.body.appendChild(banner);
  setTimeout(removeBanner, 3000);
}
```

**Cambio nel callback `onSave` del banner attuale** — in `maybeShowBanner`:
```js
showSaveBanner(cred, () => {
  showReviewForm(cred);   // prima era: chrome.runtime.sendMessage SAVE_CREDENTIAL
}, () => {
  clearPending();
});
```

---

## 7. Test plan manuale extension

| ID | Scenario | Passi | Risultato atteso |
|---|---|---|---|
| T-L01 | Overlay si apre al click "Salva" | Submit form login su pagina nuova → clicca "Salva" nel banner | Overlay review compare con campi pre-compilati |
| T-L02 | Campi modificabili | Overlay aperto → modifica username → Salva | Credenziale salvata con username modificato |
| T-L03 | Errore 422 inline | Overlay → svuota campo Nome → Salva | Overlay resta aperto, messaggio errore rosso visibile |
| T-L04 | Salvataggio riuscito | Overlay → dati validi → Salva | Overlay sparisce, banner verde "X salvata." per 3s |
| T-L05 | Annulla | Overlay aperto → Annulla | Overlay sparisce, pending rimosso da storage |
| T-L06 | Token scaduto durante review | Token scaduto → Salva nel overlay | Overlay chiude, compare banner auth |
| T-L07 | CSS isolato | Testare su pagine con CSS aggressivo (Bootstrap, Tailwind) | Overlay non è distorto dagli stili della pagina |
| T-L08 | PUT update (via background test) | Invia `UPDATE_CREDENTIAL` con id valido da background | 200 ok con `{ id, name }` aggiornato |
