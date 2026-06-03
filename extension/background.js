// Stub — gestione messaggi completa in storia F (background service worker).
chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.type === 'SAVE_CREDENTIAL') {
    console.log('[PM background] SAVE_CREDENTIAL ricevuto', message.payload);
    sendResponse({ status: 'stub' });
  }
  return true;
});
