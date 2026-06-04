# Piano — Storia I: banner installazione browser extension

Issue: [#69](https://github.com/alkcxy/password-manager/issues/69)  
Branch: `feature/story-i-web-app-banner`

## 1. Cosa dice l'issue (vs ADR)

L'ADR menziona solo "banner/suggerimento installazione extension". L'issue #69 specifica:
- Il banner compare **solo** se `window.__pmExtensionInstalled` non è `true` (iniettato dal content script al caricamento della pagina)
- Dismissione **persistente** via `localStorage` (chiave suggerita: `pm_extension_banner_dismissed`)
- Link Chrome Web Store (placeholder — extension non ancora pubblicata su CWS)
- Stile Bootstrap coerente, Stimulus se necessario

## 2. Ambiente

Rails 8, Hotwire, Bootstrap 5.3, Stimulus con import-map. Nessun tooling Node.js.

## 3. Verifiche di config

- Il content script (`extension/content_script.js`) **non setta** ancora `window.__pmExtensionInstalled = true` — va aggiunto.
- `app/views/shared/` non esiste — va creata con il partial.
- Stimulus controllers registrati in `app/javascript/controllers/index.js` con `import + application.register(...)`.
- Suite test include system test Capybara con JS — test automatici fattibili.

## 4. Prerequisiti

| Prerequisito | Piano |
|---|---|
| `window.__pmExtensionInstalled = true` nel content script | Aggiungere in cima a `extension/content_script.js` |
| Chrome Web Store URL | Placeholder `#` con nota inline nel template |
| Cartella `app/views/shared/` | Creare al momento del partial |

## 5. Implementazione

1. **`extension/content_script.js`**: aggiungere `window.__pmExtensionInstalled = true;` come prima istruzione (inizio IIFE).

2. **`app/javascript/controllers/extension_banner_controller.js`**: controller Stimulus che a `connect()` nasconde il banner se `localStorage.getItem('pm_extension_banner_dismissed')` è settato o se `window.__pmExtensionInstalled === true`; action `dismiss()` che setta localStorage e rimuove il banner.

3. **`app/views/shared/_extension_banner.html.erb`**: Bootstrap alert `alert-info` dismissibile, con icona puzzle, testo suggerimento installazione, link CWS (placeholder `#`), pulsante chiudi via Stimulus.

4. **`app/views/layouts/application.html.erb`**: `<%= render 'shared/extension_banner' if logged_in? %>` subito dopo la navbar, prima del `yield`.

5. **`app/javascript/controllers/index.js`**: import + register di `ExtensionBannerController` come `"extension-banner"`.

## 6. Strategia di test

System test (Capybara, JS abilitato) — `test/system/extension_banner_test.rb`:

| Caso | Come testare |
|---|---|
| Banner visibile al primo accesso | Login, visit credentials — assert banner presente |
| Banner assente se extension installata | `page.execute_script("window.__pmExtensionInstalled = true")` + visit — assert banner assente |
| Banner si chiude al click su Chiudi | Click dismiss — assert banner assente |
| Banner non riappare dopo dismiss | Dopo dismiss, revisit — assert banner assente (localStorage persiste in sessione Capybara) |
