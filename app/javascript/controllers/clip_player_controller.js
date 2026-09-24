import { Controller } from "@hotwired/stimulus"

// Plays the current clip (first N seconds) and refreshes the page when the next stage starts.
// The page is morphed on refresh, so the timer is rescheduled whenever the server sends a new value.
export default class extends Controller {
  static targets = [ "audio" ]
  static values = { seconds: Number, refreshIn: Number }

  connect() {
    this.schedule()
  }

  refreshInValueChanged() {
    this.schedule()
  }

  disconnect() {
    clearTimeout(this.refreshTimer)
    clearTimeout(this.stopTimer)
  }

  schedule() {
    clearTimeout(this.refreshTimer)
    if (this.refreshInValue > 0) {
      this.refreshTimer = setTimeout(() => window.Turbo.visit(window.location.href, { action: "replace" }), this.refreshInValue)
    }
  }

  play() {
    clearTimeout(this.stopTimer)
    this.audioTarget.currentTime = 0
    this.audioTarget.play()
    this.stopTimer = setTimeout(() => this.audioTarget.pause(), this.secondsValue * 1000)
  }
}
