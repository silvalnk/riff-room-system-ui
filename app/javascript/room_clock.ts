export type RoomState = {
  videoId?: string
  startedAt?: string
  playback?: string
  seed?: string
  nextIndex?: string
  djId?: string
  phase?: string
  hits?: string
  lastEvent?: string
  failedName?: string
  serverNow?: string
}

let seenServerNow: number | null = null
let clockOffset = 0

export function roomState(): RoomState {
  return document.getElementById("room_state")?.dataset ?? {}
}

export function nowMs(): number {
  const serverNow = Number(roomState().serverNow)
  if (serverNow && serverNow !== seenServerNow) {
    seenServerNow = serverNow
    clockOffset = serverNow - Date.now()
  }
  return Date.now() + clockOffset
}

export function elapsedSeconds(): number {
  const started = Number(roomState().startedAt)
  if (!started) return 0
  return Math.max(0, (nowMs() - started) / 1000)
}
