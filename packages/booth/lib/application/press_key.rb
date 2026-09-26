module Booth
  module Application
    class PressKey
      def initialize(repository:, clock:, seeds:)
        @repository = repository
        @clock = clock
        @seeds = seeds
      end

      def call(profile_id:, letter:, note_index:, now_ms:)
        result = @repository.transaction do
          room = @repository.load
          judged = @repository.judgement(room.playing_entry&.id, note_index)
          pressed = room.press(profile_id: profile_id, letter: letter, note_index: note_index, now_ms: now_ms, already_judged: judged)
          next { result: pressed.press_result } unless pressed.changed

          if pressed.failed
            nxt = pressed.next_waiting
            pressed = pressed.handoff(now_ms: @clock.call, seed: nxt && @seeds.call(nxt), event: "TurnFailed")
          end
          @repository.update_state(pressed)
          { result: pressed.press_result, failed: pressed.failed }
        end
        result == :stale ? { result: :ignored } : result
      end
    end
  end
end
