import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    text: String,
    url: String,
    clearAfter: { type: Number, default: 30000 }
  }

  copy() {
    if (this.hasUrlValue) {
      fetch(this.urlValue, { headers: { Accept: "application/json" } })
        .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
        .then(({ password }) => this.#write(password))
        .catch(() => this.#flash("🚫"))
    } else {
      this.#write(this.textValue)
    }
  }

  #write(text) {
    if (!navigator.clipboard) { this.#flash("🚫"); return }
    navigator.clipboard.writeText(text).then(() => {
      this.#flash("✓")
      setTimeout(() => navigator.clipboard.writeText(""), this.clearAfterValue)
    }).catch(() => this.#flash("🚫"))
  }

  #flash(icon) {
    const original = this.element.textContent
    this.element.textContent = icon
    this.element.disabled = true
    setTimeout(() => {
      this.element.textContent = original
      this.element.disabled = false
    }, 2000)
  }
}
