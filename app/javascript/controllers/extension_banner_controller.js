import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (localStorage.getItem("pm_extension_banner_dismissed") ||
        document.documentElement.hasAttribute('data-pm-ext-installed')) {
      this.element.remove()
      return
    }
    // Content script runs at document_idle (after Stimulus connects) — watch for late injection
    this._observer = new MutationObserver(() => {
      if (document.documentElement.hasAttribute('data-pm-ext-installed')) {
        this._observer.disconnect()
        this.element.remove()
      }
    })
    this._observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-pm-ext-installed']
    })
  }

  disconnect() {
    this._observer?.disconnect()
  }

  dismiss() {
    localStorage.setItem("pm_extension_banner_dismissed", "1")
    this.element.remove()
  }
}
