import { Controller } from "@hotwired/stimulus"
import { roomState } from "room_clock"

export default class extends Controller<HTMLElement> {
  declare watch: MutationObserver | undefined
  declare timer: number | undefined
  declare shown: string | undefined

  connect(): void {
    this.watch = new MutationObserver(() => this.onChange())
    const state = document.getElementById("room_state")
    if (state) this.watch.observe(state, { attributes: true })
    this.onChange()
  }

  disconnect(): void {
    this.watch?.disconnect()
    window.clearTimeout(this.timer)
  }

  onChange(): void {
    const state = roomState()
    if (state.lastEvent !== "TurnFailed") return
    const mark = `${state.failedName}:${state.videoId}:${state.djId}`
    if (mark === this.shown) return
    this.shown = mark
    const name = state.failedName || "DJ"
    this.element.hidden = false
    this.element.textContent = `${name} falhou. A vez passou.`
    window.clearTimeout(this.timer)
    this.timer = window.setTimeout(() => { this.element.hidden = true }, 6000)
  }
}
