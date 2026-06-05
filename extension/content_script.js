(function () {
  'use strict';

  // Segnala alla web app che l'estensione è attiva su questa pagina.
  // localStorage persiste per le navigazioni successive; l'evento rimuove
  // immediatamente il banner se Stimulus si è connesso prima di questo script.
  try { localStorage.setItem('pm_ext_installed', '1'); } catch (_) {}
  window.dispatchEvent(new CustomEvent('pm-ext-installed'));

  const BANNER_ID = 'pm-save-banner';
  const REVIEW_ID = 'pm-review-form';
  const STORAGE_KEY = 'pmPendingCred';
  const USERNAME_KEY = 'pmPendingUsername';
  const attachedForms = new WeakSet();
  const attachedFields = new WeakSet();
  let pendingCredential = null;
  let pendingUsername = null;

  // Recupera username pendente da un eventuale redirect precedente
  chrome.storage.local.get(USERNAME_KEY, (result) => {
    if (!chrome.runtime.lastError && result && result[USERNAME_KEY]) {
      pendingUsername = result[USERNAME_KEY];
    }
  });

  function isUsernameInput(input) {
    if (!['text', 'email', 'tel'].includes(input.type)) return false;
    return (
      /username|email/i.test(input.autocomplete || '') ||
      /user|email|login|name/i.test([input.name, input.id, input.placeholder].join(' '))
    );
  }

  function findUsernameField(container, passwordField) {
    const inputs = Array.from(container.querySelectorAll('input'));
    const pwIndex = inputs.indexOf(passwordField);
    const before = pwIndex >= 0 ? inputs.slice(0, pwIndex) : inputs;
    const candidates = before.filter(i =>
      ['text', 'email', 'tel'].includes(i.type) ||
      /user|email|login|name/i.test([i.name, i.id, i.placeholder].join(' '))
    );
    return candidates[candidates.length - 1] || null;
  }

  function findContainer(field) {
    let el = field.parentElement;
    while (el && el !== document.body) {
      if (el.querySelector('input[type="text"], input[type="email"], input[type="tel"]')) return el;
      el = el.parentElement;
    }
    return document.body;
  }

  function findSubmitButton(field) {
    const inputWrapper = field.parentElement;
    let container = inputWrapper.parentElement;
    for (let i = 0; i < 8 && container && container !== document.body; i++) {
      const candidates = Array.from(container.querySelectorAll('button, input[type="submit"]'))
        .filter(b =>
          !inputWrapper.contains(b) &&
          (inputWrapper.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING)
        );
      if (candidates.length) return candidates[0];
      container = container.parentElement;
    }
    return null;
  }

  function removeBanner() {
    const el = document.getElementById(BANNER_ID);
    if (el) el.remove();
  }

  function removeReviewForm() {
    const el = document.getElementById(REVIEW_ID);
    if (el) el.remove();
  }

  function makeField(labelText, type, value, autocomplete) {
    const wrapper = document.createElement('div');
    wrapper.style.cssText = 'margin-bottom:12px';

    const label = document.createElement('label');
    label.textContent = labelText;
    label.style.cssText =
      'display:block;font-size:12px;font-weight:600;color:#64748b;' +
      'margin-bottom:4px;font-family:system-ui,sans-serif';

    const input = document.createElement('input');
    input.type = type;
    input.value = value;
    input.autocomplete = autocomplete;
    input.style.cssText =
      'display:block;width:100%;box-sizing:border-box;padding:8px 10px;' +
      'font-size:14px;font-family:system-ui,sans-serif;color:#1e293b;' +
      'border:1px solid #cbd5e1;border-radius:6px;background:#fff;outline:none;margin:0';
    input.addEventListener('focus', () => { input.style.borderColor = '#3b82f6'; });
    input.addEventListener('blur',  () => { input.style.borderColor = '#cbd5e1'; });

    wrapper.append(label, input);
    return { wrapper, input };
  }

  function showReviewForm(cred, options = {}) {
    removeReviewForm();
    removeBanner();

    const overlay = document.createElement('div');
    overlay.id = REVIEW_ID;
    overlay.style.cssText =
      'position:fixed;top:0;left:0;right:0;bottom:0;z-index:2147483647;' +
      'display:flex;align-items:center;justify-content:center;' +
      'background:rgba(0,0,0,0.5);font-family:system-ui,sans-serif';

    const box = document.createElement('div');
    box.style.cssText =
      'background:#fff;border-radius:10px;padding:24px;width:340px;' +
      'max-width:calc(100vw - 32px);box-shadow:0 8px 32px rgba(0,0,0,0.25);color:#1e293b';

    const title = document.createElement('h2');
    title.textContent = (cred.id && !options.autoSaveFailed) ? 'Modifica credenziale' : 'Salva credenziale';
    title.style.cssText =
      'margin:0 0 16px;font-size:16px;font-weight:700;' +
      'font-family:system-ui,sans-serif;color:#1e293b';

    const errorDiv = document.createElement('div');
    errorDiv.style.cssText =
      'display:none;background:#fef2f2;border:1px solid #fca5a5;border-radius:6px;' +
      'padding:8px 12px;font-size:13px;color:#dc2626;margin-bottom:12px;' +
      'font-family:system-ui,sans-serif';

    const { wrapper: nameWrap,     input: nameInput     } = makeField('Nome',     'text',     cred.name     || '', 'off');
    const { wrapper: usernameWrap, input: usernameInput } = makeField('Username', 'text',     cred.username || '', 'off');
    const { wrapper: passwordWrap, input: passwordInput } = makeField('Password', 'password', cred.password || '', 'new-password');
    const { wrapper: urlWrap,      input: urlInput      } = makeField('URL',      'text',     cred.url      || '', 'off');

    const btnRow = document.createElement('div');
    btnRow.style.cssText = 'display:flex;gap:8px;margin-top:16px';

    const saveBtn = document.createElement('button');
    saveBtn.textContent = 'Salva';
    saveBtn.style.cssText =
      'flex:1;padding:9px 16px;font-size:14px;font-weight:600;font-family:system-ui,sans-serif;' +
      'background:#3b82f6;color:#fff;border:none;border-radius:6px;cursor:pointer';

    const cancelBtn = document.createElement('button');
    cancelBtn.textContent = 'Annulla';
    cancelBtn.style.cssText =
      'padding:9px 16px;font-size:14px;font-family:system-ui,sans-serif;' +
      'background:transparent;color:#64748b;border:1px solid #e2e8f0;border-radius:6px;cursor:pointer';

    btnRow.append(saveBtn, cancelBtn);

    const boxChildren = [title];
    if (options.autoSaveFailed) {
      const noticeDiv = document.createElement('div');
      noticeDiv.style.cssText =
        'background:#fef3c7;border:1px solid #fcd34d;border-radius:6px;' +
        'padding:8px 12px;font-size:13px;color:#92400e;margin-bottom:12px;' +
        'font-family:system-ui,sans-serif';
      noticeDiv.textContent = options.errorMsg || 'Salvataggio automatico non riuscito. Verifica i dati e riprova.';
      boxChildren.push(noticeDiv);
    }
    boxChildren.push(errorDiv, nameWrap, usernameWrap, passwordWrap, urlWrap, btnRow);
    box.append(...boxChildren);

    overlay.appendChild(box);
    document.body.appendChild(overlay);

    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) { clearPending(); removeReviewForm(); }
    });

    nameInput.focus();

    const fields = { name: nameInput, username: usernameInput, password: passwordInput, url: urlInput };
    saveBtn.addEventListener('click', () => handleReviewSave(cred, saveBtn, errorDiv, fields));
    cancelBtn.addEventListener('click', () => { clearPending(); removeReviewForm(); });
  }

  async function handleReviewSave(cred, saveBtn, errorDiv, fields) {
    saveBtn.disabled = true;
    saveBtn.style.background = '#93c5fd';
    errorDiv.style.display = 'none';

    const payload = {
      name:     fields.name.value.trim(),
      username: fields.username.value.trim(),
      password: fields.password.value,
      url:      fields.url.value.trim(),
    };
    const messageType = cred.id ? 'UPDATE_CREDENTIAL' : 'SAVE_CREDENTIAL';
    if (cred.id) payload.id = cred.id;

    let response;
    try {
      response = await chrome.runtime.sendMessage({ type: messageType, payload });
    } catch (_) {
      saveBtn.disabled = false;
      saveBtn.style.background = '#3b82f6';
      errorDiv.textContent = 'Errore di comunicazione con il background.';
      errorDiv.style.display = 'block';
      return;
    }

    if (response.status === 'ok') {
      clearPending();
      removeReviewForm();
      showConfirmBanner(`"${payload.name}" salvata.`);
    } else if (response.status === 'error' && response.errors) {
      saveBtn.disabled = false;
      saveBtn.style.background = '#3b82f6';
      errorDiv.textContent = response.errors.join(' — ');
      errorDiv.style.display = 'block';
    } else if (response.status === 'TOKEN_EXPIRED') {
      clearPending();
      removeReviewForm();
      showAuthBanner();
    } else {
      saveBtn.disabled = false;
      saveBtn.style.background = '#3b82f6';
      errorDiv.textContent = 'Errore nel salvataggio. Riprova.';
      errorDiv.style.display = 'block';
    }
  }

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

  function makeButton(label, bg, color) {
    const btn = document.createElement('button');
    btn.textContent = label;
    btn.style.cssText =
      `background:${bg};color:${color};border:none;padding:6px 14px;` +
      'border-radius:4px;cursor:pointer;font-size:13px;font-family:inherit';
    return btn;
  }

  function showSaveBanner(credential, onSave, onIgnore) {
    removeBanner();

    const banner = document.createElement('div');
    banner.id = BANNER_ID;
    banner.style.cssText =
      'position:fixed;top:0;left:0;right:0;z-index:2147483647;' +
      'background:#1e293b;color:#f8fafc;padding:12px 16px;' +
      'display:flex;align-items:center;gap:12px;' +
      'font-family:system-ui,sans-serif;font-size:14px;' +
      'box-shadow:0 2px 8px rgba(0,0,0,0.35)';

    const text = document.createElement('span');
    text.style.flex = '1';
    text.textContent = `Salva "${credential.username || '(utente)'}" nel password manager?`;

    const btnSave = makeButton('Salva', '#3b82f6', '#fff');
    const btnIgnore = makeButton('Ignora', 'transparent', '#94a3b8');

    btnSave.addEventListener('click', () => { removeBanner(); onSave(); });
    btnIgnore.addEventListener('click', () => { removeBanner(); onIgnore(); });

    banner.append(text, btnSave, btnIgnore);
    document.body.appendChild(banner);
  }

  function storePendingUsername(username) {
    pendingUsername = username;
    chrome.storage.local.set({ [USERNAME_KEY]: username });
  }

  function clearPendingUsername() {
    pendingUsername = null;
    chrome.storage.local.remove(USERNAME_KEY);
  }

  function storePending(cred) {
    pendingCredential = cred;
    clearPendingUsername();
    chrome.storage.local.set({ [STORAGE_KEY]: cred });
  }

  function clearPending() {
    pendingCredential = null;
    chrome.storage.local.remove(STORAGE_KEY);
  }

  function showAuthBanner() {
    removeBanner();
    clearPending();

    const banner = document.createElement('div');
    banner.id = BANNER_ID;
    banner.style.cssText =
      'position:fixed;top:0;left:0;right:0;z-index:2147483647;' +
      'background:#1e293b;color:#f8fafc;padding:12px 16px;' +
      'display:flex;align-items:center;gap:12px;' +
      'font-family:system-ui,sans-serif;font-size:14px;' +
      'box-shadow:0 2px 8px rgba(0,0,0,0.35)';

    const text = document.createElement('span');
    text.style.flex = '1';
    text.textContent = 'Accedi all\'estensione per salvare le credenziali su questo sito.';

    banner.append(text);
    document.body.appendChild(banner);
  }

  function showSuccessBannerWithEdit(name, savedCred) {
    removeBanner();
    const banner = document.createElement('div');
    banner.id = BANNER_ID;
    banner.style.cssText =
      'position:fixed;top:0;left:0;right:0;z-index:2147483647;' +
      'background:#16a34a;color:#fff;padding:12px 16px;' +
      'display:flex;align-items:center;gap:12px;' +
      'font-family:system-ui,sans-serif;font-size:14px;' +
      'box-shadow:0 2px 8px rgba(0,0,0,0.35)';

    const text = document.createElement('span');
    text.style.flex = '1';
    text.textContent = `"${name}" salvata.`;

    const editBtn = makeButton('Modifica', 'rgba(255,255,255,0.25)', '#fff');
    editBtn.addEventListener('click', () => {
      removeBanner();
      showReviewForm(savedCred);
    });

    banner.append(text, editBtn);
    document.body.appendChild(banner);
    setTimeout(removeBanner, 5000);
  }

  async function handleAutoSave(cred) {
    let response;
    try {
      response = await chrome.runtime.sendMessage({
        type: 'SAVE_CREDENTIAL',
        payload: { name: cred.name, username: cred.username, password: cred.password, url: cred.url },
      });
    } catch (_) {
      showReviewForm(cred, { autoSaveFailed: true, errorMsg: 'Errore di comunicazione. Verifica i dati e riprova.' });
      return;
    }

    if (response.status === 'ok') {
      clearPending();
      const savedCred = { ...cred, id: response.data.id };
      showSuccessBannerWithEdit(cred.name, savedCred);
    } else if (response.status === 'TOKEN_EXPIRED') {
      clearPending();
      showAuthBanner();
    } else {
      const errorMsg = (response.errors || []).join(' — ') || 'Salvataggio automatico non riuscito. Verifica i dati e riprova.';
      showReviewForm(cred, { autoSaveFailed: true, errorMsg });
    }
  }

  async function maybeShowBanner(cred) {
    if (!cred) return;

    let authIssue = false;
    try {
      const res = await chrome.runtime.sendMessage({
        type: 'GET_CREDENTIALS',
        payload: { domain: cred.name }
      });

      if (res && (res.status === 'TOKEN_EXPIRED' || res.status === 'NOT_CONFIGURED')) {
        authIssue = true;
      } else if (res && res.status === 'ok' && res.data && res.data.length > 0) {
        clearPending();
        return;
      }
    } catch (_) {}

    if (authIssue) {
      showAuthBanner();
      return;
    }

    clearPending();
    showSaveBanner(cred, () => {
      handleAutoSave(cred);
    }, () => {});
  }

  function showPendingBannerIfSucceeded() {
    if (pendingCredential) {
      maybeShowBanner(pendingCredential);
    } else {
      chrome.storage.local.get(STORAGE_KEY, (result) => {
        if (chrome.runtime.lastError) return;
        maybeShowBanner((result && result[STORAGE_KEY]) || null);
      });
    }
  }

  function captureCredential(passwordField, container) {
    if (!passwordField.value) return;
    const usernameField = findUsernameField(container, passwordField);
    // Usa username trovato nella pagina; se assente, usa quello salvato dalla fase 1
    const username = usernameField ? usernameField.value : (pendingUsername || '');
    let name = window.location.href;
    try { name = new URL(window.location.href).hostname; } catch (_) {}
    storePending({ name, username, password: passwordField.value, url: window.location.href });
  }

  function captureUsernameOnly(container) {
    const field = Array.from(container.querySelectorAll('input')).find(isUsernameInput);
    if (field && field.value) storePendingUsername(field.value);
  }

  // Caso 1: <form> — gestisce sia login completo che fase 1 (solo username)
  function attachToForm(form) {
    if (attachedForms.has(form)) return;
    attachedForms.add(form);
    form.addEventListener('submit', () => {
      const passwordField = form.querySelector('input[type="password"]');
      if (passwordField) captureCredential(passwordField, form);
      else captureUsernameOnly(form);
    }, true);
  }

  // Caso 2: campo password senza <form> (Authelia, React, ecc.)
  function attachToField(passwordField) {
    if (attachedFields.has(passwordField)) return;
    attachedFields.add(passwordField);
    const container = findContainer(passwordField);
    const capture = () => captureCredential(passwordField, container);
    const submitBtn = findSubmitButton(passwordField);
    if (submitBtn) submitBtn.addEventListener('click', capture);
    container.addEventListener('keydown', (e) => { if (e.key === 'Enter') capture(); });
  }

  // Caso 3: campo username senza password nella pagina (fase 1 two-phase auth, no <form>)
  function attachToUsernameOnlyField(usernameField) {
    if (attachedFields.has(usernameField)) return;
    attachedFields.add(usernameField);
    const capture = () => { if (usernameField.value) storePendingUsername(usernameField.value); };
    const submitBtn = findSubmitButton(usernameField);
    if (submitBtn) submitBtn.addEventListener('click', capture);
    usernameField.addEventListener('keydown', (e) => { if (e.key === 'Enter') capture(); });
  }

  function onNavigated() {
    showPendingBannerIfSucceeded();
    scanForms();
  }

  function scanForms() {
    const passwordFields = document.querySelectorAll('input[type="password"]');

    passwordFields.forEach(field => {
      const form = field.closest('form');
      if (form) attachToForm(form);
      else attachToField(field);
    });

    // Se non ci sono campi password: cerca username per fase 1
    if (passwordFields.length === 0) {
      document.querySelectorAll('form').forEach(form => attachToForm(form));
      document.querySelectorAll('input').forEach(input => {
        if (isUsernameInput(input) && !input.closest('form')) {
          attachToUsernameOnlyField(input);
        }
      });
    }
  }

  // ── Autofill dal popup ──────────────────────────────────────────────────

  function setNativeValue(input, value) {
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
    setter.call(input, value);
    input.dispatchEvent(new Event('input', { bubbles: true }));
    input.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function fillCredential({ username, password }) {
    const passwordField = Array.from(document.querySelectorAll('input[type="password"]'))
      .find(f => f.offsetParent !== null);
    if (!passwordField) return;

    if (password) setNativeValue(passwordField, password);

    if (username) {
      const usernameField = findUsernameField(document.body, passwordField);
      if (usernameField) setNativeValue(usernameField, username);
    }
  }

  chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
    if (message.type === 'FILL') {
      fillCredential(message.payload);
      sendResponse({ status: 'ok' });
    }
    if (message.type === 'HAS_PASSWORD_FIELD') {
      sendResponse({ hasPasswordField: !!document.querySelector('input[type="password"]') });
    }
    return true;
  });

  // Turbo Drive (Rails)
  document.addEventListener('turbo:load', onNavigated);

  // SPA: React Router, Vue Router, Next.js, ecc.
  const origPushState = history.pushState.bind(history);
  history.pushState = function (...args) { origPushState(...args); onNavigated(); };
  window.addEventListener('popstate', onNavigated);

  // Iniezione dinamica di campi
  new MutationObserver(scanForms).observe(document.documentElement, { childList: true, subtree: true });

  // Rimuove il banner di installazione estensione dalla web app.
  // MutationObserver dedicato: cattura il banner anche se viene aggiunto dopo
  // l'esecuzione del content script (Turbo morph, render dinamico, ecc.).
  function removeInstallBanner() {
    document.querySelectorAll('[data-controller="extension-banner"]').forEach(el => el.remove());
  }
  removeInstallBanner();
  document.addEventListener('turbo:load', removeInstallBanner);
  new MutationObserver(removeInstallBanner).observe(document.documentElement, {
    childList: true, subtree: true
  });

  showPendingBannerIfSucceeded();
  scanForms();
}());
