(function () {
  'use strict';

  const BANNER_ID = 'pm-save-banner';
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

  function attachToForm(form) {
    if (attachedForms.has(form)) return;
    attachedForms.add(form);

    form.addEventListener('submit', () => {
      const passwordField = form.querySelector('input[type="password"]');
      if (!passwordField || !passwordField.value) return;

      const usernameField = findUsernameField(form, passwordField);
      let name = window.location.href;
      try { name = new URL(window.location.href).hostname; } catch (_) {}

      pendingCredential = {
        name,
        username: usernameField ? usernameField.value : '',
        password: passwordField.value,
        url: window.location.href,
      };
    }, true);
  }

  function showPendingBannerIfSucceeded() {
    if (!pendingCredential) return;
    // Login fallita: siamo ancora sulla stessa pagina
    if (window.location.href === pendingCredential.url) {
      pendingCredential = null;
      return;
    }
    const cred = pendingCredential;
    pendingCredential = null;
    showSaveBanner(cred, () => {
      chrome.runtime.sendMessage({ type: 'SAVE_CREDENTIAL', payload: cred });
    }, () => {});
  }

  function scanForms() {
    document.querySelectorAll('input[type="password"]').forEach(field => {
      const form = field.closest('form');
      if (form) attachToForm(form);
    });
  }

  document.addEventListener('turbo:load', () => {
    showPendingBannerIfSucceeded();
    scanForms();
  });

  new MutationObserver(scanForms).observe(document.documentElement, { childList: true, subtree: true });
  scanForms();
}());
