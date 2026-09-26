module Booth
  module Application
    class EnqueueSong
      def initialize(repository:, clock:, seeds:)
        @repository = repository
        @clock = clock
        @seeds = seeds
      end

      def call(profile_id:, profile_name:, raw_url:)
        video_id = YoutubeUrl.extract(raw_url)
        return Presence::Notice.new([ "YouTube URL is invalid" ]) if video_id.nil?

        result = @repository.transaction do
          room = @repository.load
          queued = room.enqueue(
            profile_id: profile_id,
            profile_name: profile_name,
            video_id: video_id,
            position: room.entries.map(&:position).max.to_i + 1
          )
          next queued.notice unless queued.ok?

          queued = @repository.insert_new_entries(queued)
          if queued.idle?
            entry = queued.next_waiting
            queued = queued.start_turn(entry: entry, now_ms: @clock.call, seed: @seeds.call(entry))
          end
          @repository.update_state(queued)
          Presence::Notice.new
        end
        stale(result)
      end

      private
        def stale(result)
          return Presence::Notice.new([ "room changed, retry" ]) if result == :stale

          result
        end
    end
  end
end
