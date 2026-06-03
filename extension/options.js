function validateUrl(input, value) {
  if (!value) return "Inserisci un URL.";
  if (!input.validity.valid) return "URL non valida.";
  if (!value.startsWith("https://")) return "L'URL deve usare HTTPS.";
  return null;
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
  input.value = value;
  const error = validateUrl(input, value);

  errorMsg.textContent = error ?? "";
  input.classList.toggle("error", error !== null);
  status.textContent = "";

  if (error) return;

  chrome.storage.sync.set({ baseUrl: value }, () => {
    status.textContent = "Salvato.";
    setTimeout(() => window.close(), 800);
  });
});
