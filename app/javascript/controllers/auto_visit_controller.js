import { Controller } from "@hotwired/stimulus"

// Sends the user straight to a freshly started round.
export default class extends Controller {
  static values = { url: String }

  connect() {
    window.Turbo.visit(this.urlValue)
  }
}
