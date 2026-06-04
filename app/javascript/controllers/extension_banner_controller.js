import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (localStorage.getItem("pm_extension_banner_dismissed") || window.__pmExtensionInstalled) {
      this.element.remove()
    }
  }

  dismiss() {
    localStorage.setItem("pm_extension_banner_dismissed", "1")
    this.element.remove()
  }
}
