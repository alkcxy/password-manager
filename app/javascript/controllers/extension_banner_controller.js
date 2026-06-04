import { Controller } from "@hotwired/stimulus"

// Tempo massimo di attesa per il segnale del content script (document_idle).
// Se entro questo intervallo non arriva nulla, il banner viene mostrato.
const EXTENSION_SIGNAL_TIMEOUT_MS = 400

export default class extends Controller {
  connect() {
    if (this._extensionPresent()) {
      this.element.remove()
      return
    }
    this._onExt = () => {
      clearTimeout(this._timer)
      this.element.remove()
    }
    window.addEventListener('pm-ext-installed', this._onExt, { once: true })
    this._timer = setTimeout(() => {
      if (this.element.isConnected) this.element.style.display = ''
    }, EXTENSION_SIGNAL_TIMEOUT_MS)
  }

  disconnect() {
    clearTimeout(this._timer)
    if (this._onExt) {
      window.removeEventListener('pm-ext-installed', this._onExt)
      this._onExt = null
    }
  }

  dismiss() {
    localStorage.setItem("pm_extension_banner_dismissed", "1")
    this.element.remove()
  }

  _extensionPresent() {
    return localStorage.getItem("pm_extension_banner_dismissed") ||
           localStorage.getItem("pm_ext_installed") ||
           document.documentElement.hasAttribute('data-pm-ext-installed')
  }
}
