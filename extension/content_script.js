(function () {
  'use strict';

  console.log('[PM] content script caricato su', window.location.href);

  const BANNER_ID = 'pm-save-banner';
  const attachedForms = new WeakSet();

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

  function showSaveBanner(username, password, url, onSave, onIgnore) {
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
    text.textContent = `Salva "${username || '(utente)'}" nel password manager?`;

    const btnSave = makeButton('Salva', '#3b82f6', '#fff');
    const btnIgnore = makeButton('Ignora', 'transparent', '#94a3b8');

    btnSave.addEventListener('click', () => { removeBanner(); onSave(username, password, url); });
    btnIgnore.addEventListener('click', () => { removeBanner(); onIgnore(); });

    banner.append(text, btnSave, btnIgnore);
    document.body.appendChild(banner);
  }

  function attachToForm(form) {
    if (attachedForms.has(form)) return;
    attachedForms.add(form);
    console.log('[PM] form agganciato:', form.action);

    let skipNext = false;

    form.addEventListener('submit', (e) => {
      console.log('[PM] submit intercettato, skipNext:', skipNext);
      if (skipNext) { skipNext = false; return; }

      const passwordField = form.querySelector('input[type="password"]');
      if (!passwordField || !passwordField.value) return;

      e.preventDefault();

      const password = passwordField.value;
      const usernameField = findUsernameField(form, passwordField);
      const username = usernameField ? usernameField.value : '';
      const url = window.location.href;

      showSaveBanner(username, password, url,
        (u, p, href) => {
          let hostname = href;
          try { hostname = new URL(href).hostname; } catch (_) {}
          chrome.runtime.sendMessage({
            type: 'SAVE_CREDENTIAL',
            payload: { name: hostname, username: u, password: p, url: href }
          });
          skipNext = true;
          form.requestSubmit();
        },
        () => { skipNext = true; form.requestSubmit(); }
      );
    }, true);
  }

  function scanForms() {
    const fields = document.querySelectorAll('input[type="password"]');
    console.log('[PM] scanForms:', fields.length, 'campi password trovati');
    fields.forEach(field => {
      const form = field.closest('form');
      if (form) attachToForm(form);
      else console.log('[PM] campo password senza <form> wrapper');
    });
  }

  if (document.body) {
    new MutationObserver(scanForms).observe(document.body, { childList: true, subtree: true });
    scanForms();
  } else {
    document.addEventListener('DOMContentLoaded', () => {
      new MutationObserver(scanForms).observe(document.body, { childList: true, subtree: true });
      scanForms();
    });
  }
}());
