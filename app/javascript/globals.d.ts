declare module "@hotwired/turbo-rails"

declare module "@hotwired/stimulus-loading" {
  import { Application } from "@hotwired/stimulus"

  export function eagerLoadControllersFrom(under: string, application: Application): void
}

interface YouTubePlayer {
  destroy: () => void
  seekTo: (seconds: number, allowSeekAhead: boolean) => void
  playVideo: () => void
  mute?: () => void
  unMute?: () => void
  getCurrentTime: () => number
  getPlayerState: () => number
}

interface YouTubeEvent {
  data: number
  target: YouTubePlayer
}

interface Window {
  Stimulus?: unknown
  YT?: {
    Player: new (element: HTMLElement, options: {
      videoId: string
      playerVars: { autoplay: number, controls: number, start: number, rel: number, playsinline: number }
      events: {
        onReady?: (event: YouTubeEvent) => void
        onError?: () => void
        onStateChange?: (event: YouTubeEvent) => void
      }
    }) => YouTubePlayer
    PlayerState: { ENDED: number }
  }
  onYouTubeIframeAPIReady?: () => void
  __ytReady?: Promise<void>
}
