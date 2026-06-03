(function () {
  'use strict';

  const BANNER_ID = 'pm-save-banner';
  const STORAGE_KEY = 'pmPendingCred';
  const attachedForms = new WeakSet();
  let pendingCredential = null;

  function findUsernameField(form, passwordField) {
    const inputs = Array.from(form.querySelectorAll('input'));
    const pwIndex = inputs.indexOf(passwordField);
    const before = pwIndex >= 0 ? inputs.slice(0, pwIndex) : inputs;
    const candidates = before.filter(i =>
      ['text', 'email', 'tel'].includes(i.type) ||
      /user|email|login|name/i.test([i.name, i.id, i.placeholder].join(' '))
    );
    return candidates[candidates.length - 1] || null;
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

  function storePending(cred) {
    pendingCredential = cred;
    chrome.storage.session.set({ [STORAGE_KEY]: cred });
  }

  function clearPending() {
    pendingCredential = null;
    chrome.storage.session.remove(STORAGE_KEY);
  }

  function maybeShowBanner(cred) {
    if (!cred) return;
    if (window.location.href === cred.url) { clearPending(); return; }
    clearPending();
    showSaveBanner(cred, () => {
      chrome.runtime.sendMessage({ type: 'SAVE_CREDENTIAL', payload: cred });
    }, () => {});
  }

  function showPendingBannerIfSucceeded() {
    if (pendingCredential) {
      // Stesso contesto JS (SPA/Turbo): credenziale ancora in memoria
      maybeShowBanner(pendingCredential);
    } else {
      // Contesto ricaricato (form tradizionale con redirect): leggi da storage
      chrome.storage.session.get(STORAGE_KEY, (result) => {
        maybeShowBanner(result[STORAGE_KEY] || null);
      });
    }
  }

  function attachToForm(form) {
    if (attachedForms.has(form)) return;
    attachedForms.add(form);

    form.addEventListener('submit', () => {
      const passwordField = form.querySelector('input[type="password"]');
      if (!passwordField || !passwordField.value) return;

      const usernameField = findUsernameField(form, passwordField);
      let name = window.location.href;
      try { name = new URL(window.location.href).hostname; } catch (_) {}

      storePending({
        name,
        username: usernameField ? usernameField.value : '',
        password: passwordField.value,
        url: window.location.href,
      });
    }, true);
  }

  function onNavigated() {
    showPendingBannerIfSucceeded();
    scanForms();
  }

  function scanForms() {
    document.querySelectorAll('input[type="password"]').forEach(field => {
      const form = field.closest('form');
      if (form) attachToForm(form);
    });
  }

  // Turbo Drive (Rails)
  document.addEventListener('turbo:load', onNavigated);

  // SPA: React Router, Vue Router, Next.js, ecc.
  const origPushState = history.pushState.bind(history);
  history.pushState = function (...args) { origPushState(...args); onNavigated(); };
  window.addEventListener('popstate', onNavigated);

  // Iniezione dinamica di campi password
  new MutationObserver(scanForms).observe(document.documentElement, { childList: true, subtree: true });

  // Caricamento iniziale: controlla se c'è una credenziale pendente da un redirect
  showPendingBannerIfSucceeded();
  scanForms();
}());
