chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  handleMessage(message).then(sendResponse);
  return true;
});

async function handleMessage(message) {
  switch (message.type) {
    case 'LOGIN':              return login(message.payload);
    case 'LOGOUT':             return logout();
    case 'GET_CREDENTIALS':    return getCredentials(message.payload.domain);
    case 'GET_CREDENTIAL':     return getCredential(message.payload.id);
    case 'SAVE_CREDENTIAL':    return saveCredential(message.payload);
    case 'UPDATE_CREDENTIAL':  return updateCredential(message.payload);
    default:                   return { status: 'error', message: 'Unknown message type' };
  }
}

async function getBaseUrl() {
  const { baseUrl } = await chrome.storage.sync.get('baseUrl');
  return baseUrl || null;
}

async function getStoredToken() {
  const { authToken } = await chrome.storage.local.get('authToken');
  return authToken || null;
}

async function resolveBaseUrl() {
  const baseUrl = await getBaseUrl();
  if (!baseUrl) return { error: { status: 'NOT_CONFIGURED' } };
  return { baseUrl };
}

async function resolveAuth() {
  const baseUrlResult = await resolveBaseUrl();
  if (baseUrlResult.error) return baseUrlResult;

  const authToken = await getStoredToken();
  if (!authToken || Date.now() >= authToken.expiresAt) {
    return { error: { status: 'TOKEN_EXPIRED' } };
  }

  return { baseUrl: baseUrlResult.baseUrl, token: authToken.token };
}

async function apiFetch(url, options = {}) {
  const response = await fetch(url, options);
  if (response.status === 401) return { status: 'TOKEN_EXPIRED' };
  if (response.status === 204) return { status: 'ok' };
  if (response.status === 422) {
    const data = await response.json().catch(() => ({}));
    return { status: 'error', errors: data.errors || ['Errore di validazione'] };
  }
  if (!response.ok) {
    const text = await response.text().catch(() => '');
    return { status: 'error', message: text || `HTTP ${response.status}` };
  }
  const data = await response.json();
  return { status: 'ok', data };
}

async function login({ email, password }) {
  const baseUrlResult = await resolveBaseUrl();
  if (baseUrlResult.error) return baseUrlResult.error;

  const response = await fetch(`${baseUrlResult.baseUrl}/api/sessions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => '');
    return { status: 'error', message: text || `HTTP ${response.status}` };
  }

  const data = await response.json();
  const expiresAt = new Date(data.expires_at).getTime();
  await chrome.storage.local.set({ authToken: { token: data.token, expiresAt } });
  return { status: 'ok', data };
}

async function logout() {
  const authToken = await getStoredToken();
  await chrome.storage.local.remove('authToken');

  if (!authToken || Date.now() >= authToken.expiresAt) {
    return { status: 'TOKEN_EXPIRED' };
  }

  const baseUrl = await getBaseUrl();
  if (!baseUrl) return { status: 'NOT_CONFIGURED' };

  return apiFetch(`${baseUrl}/api/sessions/${authToken.token}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${authToken.token}` },
  });
}

async function getCredentials(domain) {
  const authResult = await resolveAuth();
  if (authResult.error) return authResult.error;

  const { baseUrl, token } = authResult;
  return apiFetch(`${baseUrl}/api/credentials?domain=${encodeURIComponent(domain)}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

async function getCredential(id) {
  const authResult = await resolveAuth();
  if (authResult.error) return authResult.error;

  const { baseUrl, token } = authResult;
  return apiFetch(`${baseUrl}/api/credentials/${encodeURIComponent(id)}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

async function saveCredential({ name, username, password, url }) {
  const authResult = await resolveAuth();
  if (authResult.error) return authResult.error;

  const { baseUrl, token } = authResult;
  return apiFetch(`${baseUrl}/api/credentials`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ name, username, password, url }),
  });
}

async function updateCredential({ id, name, username, password, url, note }) {
  const authResult = await resolveAuth();
  if (authResult.error) return authResult.error;

  const { baseUrl, token } = authResult;
  return apiFetch(`${baseUrl}/api/credentials/${encodeURIComponent(id)}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ name, username, password, url, note }),
  });
}
