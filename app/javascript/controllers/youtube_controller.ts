import { Controller } from "@hotwired/stimulus"
import { elapsedSeconds, roomState, type RoomState } from "room_clock"

export default class extends Controller<HTMLElement> {
  static targets = [ "player" ]
  static values = { interruptUrl: String, syncUrl: String, userId: String }

  declare readonly playerTarget: HTMLElement
  declare readonly interruptUrlValue: string
  declare readonly syncUrlValue: string
  declare readonly userIdValue: string
  declare brokenFor: string | null
  declare mountedId: string | null
  declare seeking: boolean
  declare observer: MutationObserver | undefined
  declare keep: number
  declare timer: number | undefined
  declare player: YouTubePlayer | undefined
  declare nudged: boolean
  declare unlockSound: () => void

  connect(): void {
    this.brokenFor = null
    this.mountedId = null
    this.seeking = false
    this.nudged = false
    this.unlockSound = () => {
      this.player?.unMute?.()
      this.player?.playVideo?.()
    }
    window.addEventListener("pointerdown", this.unlockSound)
    this.observe()
    this.keep = window.setInterval(() => this.catchUp(), 2000)
    this.loadApi().then(() => this.mount())
  }

  disconnect(): void {
    window.removeEventListener("pointerdown", this.unlockSound)
    window.clearInterval(this.keep)
    window.clearInterval(this.timer)
    this.observer?.disconnect()
    this.player?.destroy?.()
  }

  state(): RoomState {
    return roomState()
  }

  viewerId(): string {
    return this.userIdValue || document.querySelector<HTMLMetaElement>("meta[name='current-user-id']")?.content || ""
  }

  loadApi(): Promise<void> {
    if (window.YT?.Player) return Promise.resolve()
    window.__ytReady ||= new Promise((resolve) => {
      const previous = window.onYouTubeIframeAPIReady
      window.onYouTubeIframeAPIReady = () => {
        previous?.()
        resolve()
      }
      const script = document.createElement("script")
      script.src = "https://www.youtube.com/iframe_api"
      document.head.appendChild(script)
    })
    return window.__ytReady
  }

  observe(): void {
    this.observer = new MutationObserver(() => this.mount())
    this.observer.observe(this.element, { childList: true, subtree: true, attributes: true })
  }

  mount(): void {
    const { videoId } = this.state()
    const youtube = window.YT
    if (!videoId || videoId === this.mountedId || !youtube) return
    this.mountedId = videoId
    this.brokenFor = null
    this.seeking = false
    this.nudged = false
    window.clearInterval(this.timer)
    this.player?.destroy?.()
    const elapsed = elapsedSeconds()
    this.playerTarget.replaceChildren()
    const node = document.createElement("div")
    this.playerTarget.appendChild(node)
    this.player = new youtube.Player(node, {
      videoId,
      playerVars: { autoplay: 1, controls: 0, start: Math.floor(elapsed), rel: 0, playsinline: 1 },
      events: {
        onReady: (event) => this.catchUp(event.target),
        onError: () => this.break("player_error"),
        onStateChange: (event) => {
          this.guardFrame(event.target)
          if (event.data === youtube.PlayerState.ENDED) {
            this.break("ended")
            return
          }
          this.catchUp(event.target)
        }
      }
    })
    if (this.viewerId() === this.state().djId) {
      this.timer = window.setInterval(() => this.sync(), 8000)
    }
  }

  catchUp(player: YouTubePlayer | undefined = this.player): void {
    this.guardFrame(player)
    if (!player?.seekTo) return
    const state = player.getPlayerState?.()
    if (state === 0) return
    const target = elapsedSeconds()
    const current = Number(player.getCurrentTime?.() ?? 0)
    const drifted = target >= 1 && (!Number.isFinite(current) || Math.abs(current - target) >= 1.5)
    if (drifted && !this.seeking) {
      this.seeking = true
      player.seekTo(target, true)
      window.setTimeout(() => { this.seeking = false }, 1200)
    }
    if (state === 1 || state === 3) return
    player.playVideo?.()
    if (this.nudged) return
    this.nudged = true
    window.setTimeout(() => {
      const now = player.getPlayerState?.()
      if (now === 1 || now === 3 || now === 0) return
      player.mute?.()
      player.playVideo?.()
    }, 800)
  }

  guardFrame(player: YouTubePlayer | undefined): void {
    const frame = this.playerTarget.querySelector("iframe")
    if (!frame) return
    const state = player?.getPlayerState?.()
    const live = state === 1 || state === 3
    frame.style.pointerEvents = live ? "none" : "auto"
    frame.tabIndex = live ? -1 : 0
    if (live && document.activeElement === frame) frame.blur()
  }

  break(reason: string): void {
    if (this.brokenFor === this.mountedId) return
    this.brokenFor = this.mountedId
    fetch(this.interruptUrlValue, {
      method: "POST",
      headers: this.headers(),
      body: new URLSearchParams({ reason })
    })
  }

  sync(): void {
    const time = this.player?.getCurrentTime?.()
    if (time == null || this.viewerId() !== this.state().djId) return
    fetch(this.syncUrlValue, {
      method: "POST",
      headers: this.headers(),
      body: new URLSearchParams({ playback_ms: String(Math.round(time * 1000)) })
    })
  }

  headers(): Record<string, string> {
    const token = document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")?.content ?? ""
    return {
      "X-CSRF-Token": token,
      "Accept": "application/json"
    }
  }
}
