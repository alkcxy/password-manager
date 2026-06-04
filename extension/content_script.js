(function () {
  'use strict';

  window.__pmExtensionInstalled = true;

  const BANNER_ID = 'pm-save-banner';
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

  function maybeShowBanner(cred) {
    if (!cred) return;
    clearPending();
    showSaveBanner(cred, () => {
      chrome.runtime.sendMessage({ type: 'SAVE_CREDENTIAL', payload: cred });
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

  showPendingBannerIfSucceeded();
  scanForms();
}());
