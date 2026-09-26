module Booth
  class Aggregate
    def self.press(state, letter:, note_index:, now_ms:, already_judged:)
      return { result: already_judged, failed: false, skipped: [] } if already_judged

      policy = Performance::FailurePolicy.new
      skipped = []
      streak = state[:streak].to_i
      total = state[:total_misses].to_i
      cursor = state[:next_note_index].to_i

      while cursor < note_index.to_i
        skipped << cursor
        streak += 1
        total += 1
        cursor += 1
        if policy.failed?(streak: streak, total: total)
          return { result: :miss, failed: true, skipped: skipped, streak: streak, total: total, next_note_index: cursor }
        end
      end

      expected = Performance::Chart.letter_at(state[:seed], note_index)
      due = Performance::Chart.due_at(state[:started_at_ms], note_index)
      result = Performance::HitWindow.judge(expected: expected, pressed: letter, due_ms: due, now_ms: now_ms)
      if result == :miss
        streak += 1
        total += 1
      else
        streak = 0
      end
      cursor = note_index.to_i + 1
      {
        result: result,
        failed: policy.failed?(streak: streak, total: total),
        skipped: skipped,
        streak: streak,
        total: total,
        next_note_index: cursor
      }
    end
  end
end
