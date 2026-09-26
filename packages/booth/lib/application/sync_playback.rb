module Booth
  module Application
    class SyncPlayback
      def initialize(repository:)
        @repository = repository
      end

      def call(profile_id:, playback_ms:)
        result = @repository.transaction do
          room = @repository.load.sync_playback(profile_id: profile_id, playback_ms: playback_ms)
          @repository.update_state(room) if room.changed
          Presence::Notice.new
        end
        result == :stale ? Presence::Notice.new([ "room changed, retry" ]) : result
      end
    end
  end
end
