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
        .catch(() => {})
    } else {
      this.#write(this.textValue)
    }
  }

  #write(text) {
    navigator.clipboard.writeText(text).then(() => {
      this.#feedback()
      setTimeout(() => navigator.clipboard.writeText(""), this.clearAfterValue)
    })
  }

  #feedback() {
    const original = this.element.textContent
    this.element.textContent = "✓"
    this.element.disabled = true
    setTimeout(() => {
      this.element.textContent = original
      this.element.disabled = false
    }, 2000)
  }
}
