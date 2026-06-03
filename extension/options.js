const VALID_URL = /^https:\/\/(localhost|\d{1,3}(\.\d{1,3}){3}|[a-zA-Z0-9][a-zA-Z0-9-]*(\.[a-zA-Z0-9][a-zA-Z0-9-]*)+)(:\d{1,5})?(\/[^\s]*)?$/;

function validateUrl(value) {
  if (!value) return "Inserisci un URL.";
  if (VALID_URL.test(value)) return null;
  if (/^http:\/\//i.test(value)) return "L'URL deve usare HTTPS.";
  return "URL non valida.";
}

const input = document.getElementById("base-url");
const errorMsg = document.getElementById("error-msg");
const status = document.getElementById("status");
const saveBtn = document.getElementById("save-btn");

chrome.storage.sync.get("baseUrl", ({ baseUrl }) => {
  if (baseUrl) input.value = baseUrl;
});

saveBtn.addEventListener("click", () => {
  const value = input.value.trim();
  const error = validateUrl(value);

  errorMsg.textContent = error ?? "";
  input.classList.toggle("error", error !== null);
  status.textContent = "";

  if (error) return;

  chrome.storage.sync.set({ baseUrl: value }, () => {
    status.textContent = "Salvato.";
    setTimeout(() => window.close(), 800);
  });
});
