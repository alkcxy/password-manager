import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this._extensionPresent()) {
      this.element.remove()
      return
    }
    // content_script.js gira a document_idle (dopo Stimulus): ascolta l'evento
    this._onExt = () => this.element.remove()
    window.addEventListener('pm-ext-installed', this._onExt, { once: true })
  }

  disconnect() {
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
