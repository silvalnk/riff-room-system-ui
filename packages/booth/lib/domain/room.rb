module Booth
  Entry = Struct.new(:id, :profile_id, :profile_name, :video_id, :position, :status, keyword_init: true)

  class Room
    attr_reader :phase, :video_id, :seed, :started_at_ms, :dj_id, :dj_name,
      :streak, :total_misses, :next_note_index, :playback_ms,
      :entries, :events, :judgements, :judgement_entry_id,
      :press_result, :notice, :failed, :changed

    def initialize(**attrs)
      @phase = attrs.fetch(:phase, "idle")
      @video_id = attrs[:video_id]
      @seed = attrs[:seed]
      @started_at_ms = attrs[:started_at_ms]
      @dj_id = attrs[:dj_id]
      @dj_name = attrs[:dj_name]
      @streak = attrs.fetch(:streak, 0)
      @total_misses = attrs.fetch(:total_misses, 0)
      @next_note_index = attrs.fetch(:next_note_index, 0)
      @playback_ms = attrs.fetch(:playback_ms, 0)
      @entries = attrs.fetch(:entries, [])
      @events = attrs.fetch(:events, [])
      @judgements = attrs.fetch(:judgements, [])
      @judgement_entry_id = attrs[:judgement_entry_id]
      @press_result = attrs[:press_result]
      @notice = attrs.fetch(:notice) { Presence::Notice.new }
      @failed = attrs.fetch(:failed, false)
      @changed = attrs.fetch(:changed, false)
    end

    def playing?
      phase == "playing"
    end

    def idle?
      phase == "idle"
    end

    def ok?
      notice.ok?
    end

    def next_waiting
      entries.select { |entry| entry.status == "waiting" }.min_by(&:position)
    end

    def playing_entry
      entries.find { |entry| entry.status == "playing" && entry.profile_id == dj_id && entry.video_id == video_id }
    end

    def enqueue(profile_id:, profile_name:, video_id:, position:)
      return reject([ "account is required" ]) if profile_id.nil?
      if entries.any? { |entry| entry.profile_id == profile_id && entry.status == "waiting" } || dj_id == profile_id
        return reject([ "already in queue" ])
      end

      entry = Entry.new(profile_id: profile_id, profile_name: profile_name, video_id: video_id, position: position, status: "waiting")
      branch(entries: entries + [ entry ], events: [ "SongQueued" ], changed: true)
    end

    def start_turn(entry:, now_ms:, seed:, record_event: true)
      return self if entry.nil?

      updated = entries.map do |item|
        next item unless item.id == entry.id

        copy = item.dup
        copy.status = "playing"
        copy
      end
      branch(
        phase: "playing",
        video_id: entry.video_id,
        seed: seed,
        started_at_ms: now_ms,
        dj_id: entry.profile_id,
        dj_name: entry.profile_name,
        streak: 0,
        total_misses: 0,
        next_note_index: 0,
        playback_ms: 0,
        entries: updated,
        events: record_event ? events + [ "TurnStarted" ] : events,
        changed: true
      )
    end

    def press(profile_id:, letter:, note_index:, now_ms:, already_judged:)
      return branch(press_result: :ignored, changed: false) unless playing? && dj_id == profile_id
      return branch(press_result: already_judged, changed: false) if already_judged

      outcome = Aggregate.press(
        { seed: seed, started_at_ms: started_at_ms, streak: streak, total_misses: total_misses, next_note_index: next_note_index },
        letter: letter, note_index: note_index, now_ms: now_ms, already_judged: nil
      )
      marks = outcome[:skipped].map { |index| { index: index, result: "miss" } }
      if outcome[:next_note_index] == note_index.to_i + 1
        marks << { index: note_index.to_i, result: outcome[:result].to_s }
      end
      branch(
        streak: outcome[:streak],
        total_misses: outcome[:total],
        next_note_index: outcome[:next_note_index],
        judgements: marks,
        judgement_entry_id: playing_entry&.id,
        press_result: outcome[:result],
        failed: outcome[:failed],
        events: outcome[:failed] ? [] : [ "Keypress" ],
        changed: true
      )
    end

    def handoff(now_ms:, seed:, event:)
      busted = Performance::FailurePolicy.new.failed?(streak: streak, total: total_misses)
      updated = entries.map do |item|
        next item unless item.status == "playing"

        copy = item.dup
        copy.status = busted ? "failed" : "done"
        copy
      end
      cleared = branch(entries: updated, phase: "handoff", dj_id: nil, dj_name: nil, video_id: nil, events: [ event ], changed: true)
      nxt = cleared.next_waiting
      return cleared.branch(phase: "idle", seed: nil, started_at_ms: nil, events: [ event ]) if nxt.nil?

      cleared.start_turn(entry: nxt, now_ms: now_ms, seed: seed, record_event: false).branch(events: [ event ])
    end

    def sync_playback(profile_id:, playback_ms:)
      return branch(changed: false) unless playing? && dj_id == profile_id

      branch(playback_ms: playback_ms.to_i, events: [ "PlaybackSync" ], changed: true)
    end

    def branch(**changes)
      self.class.new(
        phase: changes.fetch(:phase, phase),
        video_id: changes.key?(:video_id) ? changes[:video_id] : video_id,
        seed: changes.key?(:seed) ? changes[:seed] : seed,
        started_at_ms: changes.key?(:started_at_ms) ? changes[:started_at_ms] : started_at_ms,
        dj_id: changes.key?(:dj_id) ? changes[:dj_id] : dj_id,
        dj_name: changes.key?(:dj_name) ? changes[:dj_name] : dj_name,
        streak: changes.fetch(:streak, streak),
        total_misses: changes.fetch(:total_misses, total_misses),
        next_note_index: changes.fetch(:next_note_index, next_note_index),
        playback_ms: changes.fetch(:playback_ms, playback_ms),
        entries: changes.fetch(:entries, entries),
        events: changes.fetch(:events, events),
        judgements: changes.fetch(:judgements, judgements),
        judgement_entry_id: changes.fetch(:judgement_entry_id, judgement_entry_id),
        press_result: changes.fetch(:press_result, press_result),
        notice: changes.fetch(:notice, notice),
        failed: changes.fetch(:failed, failed),
        changed: changes.fetch(:changed, changed)
      )
    end

    private
      def reject(errors)
        branch(notice: Presence::Notice.new(errors), changed: false, events: [])
      end
  end
end
