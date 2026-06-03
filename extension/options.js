const TIMEOUT_MS = 5000;

async function reachable(url) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, { signal: controller.signal });
    return res.ok ? null : `Il sito ha risposto con errore (${res.status}).`;
  } catch {
    return "Impossibile raggiungere il sito.";
  } finally {
    clearTimeout(id);
  }
}

const input = document.getElementById("base-url");
const errorMsg = document.getElementById("error-msg");
const status = document.getElementById("status");
const saveBtn = document.getElementById("save-btn");

chrome.storage.sync.get("baseUrl", ({ baseUrl }) => {
  if (baseUrl) input.value = baseUrl;
});

saveBtn.addEventListener("click", async () => {
  const value = input.value.trim();

  errorMsg.textContent = "";
  input.classList.remove("error");
  status.textContent = "";

  if (!value) {
    errorMsg.textContent = "Inserisci un URL.";
    input.classList.add("error");
    return;
  }
  if (!value.startsWith("https://")) {
    errorMsg.textContent = "L'URL deve usare HTTPS.";
    input.classList.add("error");
    return;
  }

  saveBtn.disabled = true;
  status.textContent = "Verifica in corso…";

  const error = await reachable(value);

  saveBtn.disabled = false;
  status.textContent = "";
  errorMsg.textContent = error ?? "";
  input.classList.toggle("error", error !== null);

  if (error) return;

  chrome.storage.sync.set({ baseUrl: value }, () => {
    status.textContent = "Salvato.";
    setTimeout(() => window.close(), 800);
  });
});
