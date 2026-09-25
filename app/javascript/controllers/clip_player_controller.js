import { Controller } from "@hotwired/stimulus"

// Plays the current clip (first N seconds). The player's stage only changes after their own
// wrong guess, which reloads the page with the new clip length.
export default class extends Controller {
  static targets = [ "audio" ]
  static values = { seconds: Number }

  disconnect() {
    clearTimeout(this.stopTimer)
  }

  play() {
    clearTimeout(this.stopTimer)
    this.audioTarget.currentTime = 0
    this.audioTarget.play()
    this.stopTimer = setTimeout(() => this.audioTarget.pause(), this.secondsValue * 1000)
  }
}
