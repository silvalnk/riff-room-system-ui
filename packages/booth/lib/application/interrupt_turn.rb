module Booth
  module Application
    class InterruptTurn
      def initialize(repository:, clock:, seeds:)
        @repository = repository
        @clock = clock
        @seeds = seeds
      end

      def call(reason:)
        return Presence::Notice.new([ "reason is invalid" ]) unless %w[ended player_error].include?(reason.to_s)

        event = reason.to_s == "ended" ? "TurnFinished" : "TurnFailed"
        result = @repository.transaction do
          room = @repository.load
          next Presence::Notice.new unless room.playing?

          nxt = room.next_waiting
          room = room.handoff(now_ms: @clock.call, seed: nxt && @seeds.call(nxt), event: event)
          @repository.update_state(room)
          Presence::Notice.new
        end
        result == :stale ? Presence::Notice.new([ "room changed, retry" ]) : result
      end
    end
  end
end
