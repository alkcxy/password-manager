import { Controller } from "@hotwired/stimulus"

// Il content script rimuove direttamente l'elemento se l'estensione è installata.
// Questo controller gestisce solo: dismiss persistente e fallback per localStorage
// settato da install_marker.js (document_start) o da visita precedente.
const WAIT_MS = 400

export default class extends Controller {
  connect() {
    if (localStorage.getItem("pm_extension_banner_dismissed") ||
        localStorage.getItem("pm_ext_installed") ||
        document.documentElement.hasAttribute('data-pm-ext-installed')) {
      this.element.remove()
      return
    }
    this._timer = setTimeout(() => {
      if (this.element.isConnected) this.element.style.display = ''
    }, WAIT_MS)
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  dismiss() {
    localStorage.setItem("pm_extension_banner_dismissed", "1")
    this.element.remove()
  }
}
