import { Controller } from "@hotwired/stimulus"
import { nowMs, roomState, type RoomState } from "room_clock"

const LETTERS = [ "A", "S", "D", "F", "G" ] as const
const COLORS = [ "#ff6b4a", "#f5c16c", "#c4b5fd", "#7dd3fc", "#3ddea8" ]
const INTERVAL = 800
const WINDOW = 400

type Hit = { index: number, result: string }

export default class extends Controller<HTMLElement> {
  static targets = [ "canvas", "miss" ]
  static values = { pressUrl: String, userId: String }

  declare readonly canvasTarget: HTMLCanvasElement
  declare readonly missTarget: HTMLElement
  declare readonly hasMissTarget: boolean
  declare readonly pressUrlValue: string
  declare readonly userIdValue: string
  declare sent: Set<string>
  declare local: Map<number, string>
  declare seen: Set<number>
  declare video: string | undefined
  declare frame: number
  declare expiring: boolean
  declare dj: boolean
  declare missTimer: number | undefined
  declare keyListener: (event: KeyboardEvent) => void

  connect(): void {
    this.sent = new Set()
    this.local = new Map()
    this.seen = new Set(this.missIndexes())
    this.video = undefined
    this.expiring = false
    this.dj = false
    this.keyListener = (event) => this.onKey(event)
    window.addEventListener("keydown", this.keyListener)
    this.frame = window.requestAnimationFrame(() => this.draw())
  }

  disconnect(): void {
    window.removeEventListener("keydown", this.keyListener)
    window.cancelAnimationFrame(this.frame)
    window.clearTimeout(this.missTimer)
  }

  state(): RoomState {
    return roomState()
  }

  isDj(): boolean {
    const id = this.userIdValue
    return id !== "" && id === String(this.state().djId ?? "") && this.state().phase === "playing"
  }

  letterAt(index: number): (typeof LETTERS)[number] {
    return LETTERS[(Number(this.state().seed) + index * 17) % LETTERS.length]
  }

  hits(): Hit[] {
    try {
      return JSON.parse(this.state().hits || "[]") as Hit[]
    } catch {
      return []
    }
  }

  missIndexes(): number[] {
    return this.hits().filter((hit) => hit.result === "miss").map((hit) => Number(hit.index))
  }

  hit(event: Event): void {
    event.preventDefault()
    const letter = (event.currentTarget as HTMLElement).dataset.letter ?? ""
    this.press(letter)
  }

  draw(): void {
    const video = this.state().videoId
    if (video !== this.video) {
      this.video = video
      this.sent.clear()
      this.local.clear()
      this.seen = new Set(this.missIndexes())
    }
    this.revealMisses()
    const dj = this.isDj()
    if (dj !== this.dj) {
      this.dj = dj
      this.element.classList.toggle("is-dj", dj)
    }
    if (dj) this.expire()
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    if (!ctx) {
      this.frame = window.requestAnimationFrame(() => this.draw())
      return
    }
    const rect = canvas.getBoundingClientRect()
    const dpr = window.devicePixelRatio || 1
    const width = Math.max(1, Math.floor(rect.width * dpr))
    const height = Math.max(1, Math.floor(rect.height * dpr))
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width
      canvas.height = height
    }
    const { phase, startedAt, seed } = this.state()
    ctx.clearRect(0, 0, width, height)
    const lane = width / LETTERS.length
    const hitY = height - 28 * dpr
    const judged = new Map(this.hits().map((hit) => [ Number(hit.index), hit.result ]))
    LETTERS.forEach((_, column) => {
      const x = lane * column + lane / 2
      ctx.strokeStyle = "rgba(255, 255, 255, 0.08)"
      ctx.lineWidth = dpr
      ctx.beginPath()
      ctx.moveTo(x, 0)
      ctx.lineTo(x, hitY)
      ctx.stroke()
    })
    if (phase === "playing" && startedAt && seed) {
      const now = nowMs()
      const current = Math.floor((now - Number(startedAt)) / INTERVAL)
      const first = Math.max(0, current - 3)
      for (let index = first; index < current + 14; index += 1) {
        const due = Number(startedAt) + index * INTERVAL
        const y = hitY - (due - now) * 0.28 * dpr
        if (y < -40 || y > hitY + 70 * dpr) continue
        const letter = this.letterAt(index)
        const column = LETTERS.indexOf(letter)
        const x = lane * column + lane / 2
        const result = judged.get(index) || this.local.get(index)
        const radius = 18 * dpr
        ctx.beginPath()
        ctx.fillStyle = result === "hit" ? "rgba(61, 222, 138, 0.95)" : result === "miss" ? "rgba(82, 82, 91, 0.85)" : COLORS[column]
        ctx.arc(x, y, radius, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = "#fffaf3"
        ctx.font = `700 ${18 * dpr}px sans-serif`
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(result === "miss" ? "×" : letter, x, y)
      }
    }
    const gradient = ctx.createLinearGradient(0, hitY, width, hitY)
    gradient.addColorStop(0, "rgba(255, 107, 74, 0)")
    gradient.addColorStop(0.5, "rgba(255, 107, 74, 0.95)")
    gradient.addColorStop(1, "rgba(255, 107, 74, 0)")
    ctx.strokeStyle = gradient
    ctx.lineWidth = 3 * dpr
    ctx.beginPath()
    ctx.moveTo(16 * dpr, hitY)
    ctx.lineTo(width - 16 * dpr, hitY)
    ctx.stroke()
    this.frame = window.requestAnimationFrame(() => this.draw())
  }

  expire(): void {
    if (this.expiring) return
    const started = Number(this.state().startedAt)
    if (!started) return
    const now = nowMs()
    const lateIndex = Math.floor((now - started - WINDOW) / INTERVAL)
    const cursor = Number(this.state().nextIndex || 0)
    if (lateIndex < cursor || this.seen.has(cursor)) return
    this.markMiss(cursor)
    this.expiring = true
    this.send("Z", cursor, now).finally(() => { this.expiring = false })
  }

  onKey(event: KeyboardEvent): void {
    if (event.repeat) return
    const target = event.target
    if (target instanceof HTMLElement && target.closest("input, textarea, select")) return
    const letter = event.key.toUpperCase()
    if (!(LETTERS as readonly string[]).includes(letter)) return
    if (!this.isDj()) return
    event.preventDefault()
    this.press(letter)
  }

  press(letter: string): void {
    if (!this.isDj()) return
    if (!(LETTERS as readonly string[]).includes(letter)) return
    this.flash(letter)
    const now = nowMs()
    const started = Number(this.state().startedAt)
    const index = Math.max(0, Math.round((now - started) / INTERVAL))
    const due = started + index * INTERVAL
    const wrong = letter !== this.letterAt(index) || Math.abs(now - due) > WINDOW
    if (wrong) this.markMiss(index)
    this.send(letter, index, now)
  }

  markMiss(index: number): void {
    if (this.seen.has(index)) return
    this.seen.add(index)
    this.local.set(index, "miss")
    this.showMiss()
  }

  revealMisses(): void {
    this.hits().forEach((hit) => {
      if (hit.result === "miss") this.markMiss(Number(hit.index))
    })
  }

  showMiss(): void {
    if (!this.hasMissTarget) return
    const node = this.missTarget
    node.hidden = false
    node.textContent = "Errou"
    node.classList.remove("is-on")
    void node.offsetWidth
    node.classList.add("is-on")
    window.clearTimeout(this.missTimer)
    this.missTimer = window.setTimeout(() => {
      node.hidden = true
      node.classList.remove("is-on")
    }, 900)
  }

  flash(letter: string): void {
    const button = this.element.querySelector<HTMLButtonElement>(`button[data-letter="${letter}"]`)
    if (!button) return
    button.classList.add("is-down")
    window.setTimeout(() => button.classList.remove("is-down"), 140)
  }

  send(letter: string, index: number, now: number): Promise<void> {
    const mark = `${this.state().videoId}:${index}`
    if (this.sent.has(mark)) return Promise.resolve()
    this.sent.add(mark)
    const token = document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")?.content ?? ""
    return fetch(this.pressUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: new URLSearchParams({ letter, note_index: String(index), now_ms: String(now) })
    }).then((response) => response.json() as Promise<{ result?: string }>).then((body) => {
      if (body.result === "ignored") {
        this.sent.delete(mark)
        return
      }
      if (body.result) this.local.set(index, body.result)
    }).catch(() => {
      this.sent.delete(mark)
    })
  }
}
