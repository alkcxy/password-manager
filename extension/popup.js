'use strict';

const loginView = document.getElementById('login-view');
const credView  = document.getElementById('cred-view');
const loginError = document.getElementById('login-error');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const loginBtn  = document.getElementById('login-btn');
const logoutBtn = document.getElementById('logout-btn');
const credList  = document.getElementById('cred-list');
const emptyMsg  = document.getElementById('empty-msg');
const loadingMsg = document.getElementById('loading');

let activeTabId = null;
let activeDomain = null;

async function init() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab) {
    activeTabId = tab.id;
    try { activeDomain = new URL(tab.url).hostname; } catch (_) {}
  }

  const { authToken } = await chrome.storage.local.get('authToken');
  if (authToken && Date.now() < authToken.expiresAt) {
    await showCredentials();
  } else {
    showLogin();
  }
}

function showLogin(errorMsg) {
  credView.hidden = true;
  loginView.hidden = false;
  loginError.textContent = errorMsg || '';
  emailInput.focus();
}

async function showCredentials() {
  loginView.hidden = true;
  credView.hidden = false;
  credList.innerHTML = '';
  emptyMsg.hidden = true;
  loadingMsg.hidden = false;

  if (!activeDomain) {
    loadingMsg.hidden = true;
    emptyMsg.textContent = 'Impossibile determinare il dominio della pagina.';
    emptyMsg.hidden = false;
    return;
  }

  const response = await chrome.runtime.sendMessage({
    type: 'GET_CREDENTIALS',
    payload: { domain: activeDomain },
  });

  loadingMsg.hidden = true;

  if (response.status === 'TOKEN_EXPIRED') {
    showLogin();
    return;
  }

  if (response.status === 'NOT_CONFIGURED') {
    emptyMsg.textContent = 'Configura l\'URL dell\'istanza nelle opzioni dell\'extension.';
    emptyMsg.hidden = false;
    return;
  }

  if (response.status !== 'ok' || response.data.length === 0) {
    emptyMsg.hidden = false;
    return;
  }

  response.data.forEach(cred => {
    const li = document.createElement('li');
    li.innerHTML = `
      <div class="cred-info">
        <div class="cred-name">${escHtml(cred.name)}</div>
        <div class="cred-username">${escHtml(cred.username)}</div>
      </div>
      <button class="btn-fill" data-id="${escHtml(cred.id)}" data-username="${escHtml(cred.username)}">Compila</button>
    `;
    credList.appendChild(li);
  });
}

async function handleFill(credId, username) {
  const response = await chrome.runtime.sendMessage({
    type: 'GET_CREDENTIAL',
    payload: { id: credId },
  });

  if (response.status !== 'ok') return;

  const { password } = response.data;
  if (activeTabId != null) {
    chrome.tabs.sendMessage(activeTabId, {
      type: 'FILL',
      payload: { username, password },
    });
  }
  window.close();
}

async function handleLogin() {
  const email    = emailInput.value.trim();
  const password = passwordInput.value;

  if (!email || !password) {
    loginError.textContent = 'Inserisci email e password.';
    return;
  }

  loginBtn.disabled = true;
  loginError.textContent = '';

  const response = await chrome.runtime.sendMessage({
    type: 'LOGIN',
    payload: { email, password },
  });

  loginBtn.disabled = false;

  if (response.status === 'NOT_CONFIGURED') {
    showLogin('Configura prima l\'URL dell\'istanza nelle opzioni.');
    return;
  }

  if (response.status !== 'ok') {
    emailInput.classList.add('error');
    passwordInput.classList.add('error');
    loginError.textContent = 'Credenziali non valide.';
    return;
  }

  emailInput.classList.remove('error');
  passwordInput.classList.remove('error');
  await showCredentials();
}

async function handleLogout() {
  await chrome.runtime.sendMessage({ type: 'LOGOUT' });
  showLogin();
}

loginBtn.addEventListener('click', handleLogin);
logoutBtn.addEventListener('click', handleLogout);

[emailInput, passwordInput].forEach(input => {
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter') handleLogin(); });
});

credList.addEventListener('click', (e) => {
  const btn = e.target.closest('.btn-fill');
  if (btn) handleFill(btn.dataset.id, btn.dataset.username);
});

init();

function escHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
