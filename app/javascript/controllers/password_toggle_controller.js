import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "icon"]

  toggle() {
    const isPassword = this.fieldTarget.type === "password"
    this.fieldTarget.type = isPassword ? "text" : "password"
    this.iconTarget.classList.toggle("bi-eye", !isPassword)
    this.iconTarget.classList.toggle("bi-eye-slash", isPassword)
  }
}
