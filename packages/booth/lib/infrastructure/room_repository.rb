class RoomRepository
      def initialize(room:, payload: -> { {} })
        @room = room
        @payload = payload
      end

      def load
        record = @room
        Booth::Room.new(
          phase: record.phase,
          video_id: record.video_id,
          seed: record.seed,
          started_at_ms: record.started_at_ms,
          dj_id: record.dj_id,
          dj_name: record.dj&.display_name,
          streak: record.streak,
          total_misses: record.total_misses,
          next_note_index: record.next_note_index,
          playback_ms: record.playback_ms,
          entries: record.queue_entries.order(:position).map { |row| entry_from(row) }
        )
      end

      def transaction
        Room.transaction do
          @room.lock!
          yield
        end
      rescue ActiveRecord::StaleObjectError
        :stale
      end

      def insert_new_entries(room)
        record = @room
        entries = room.entries.map do |entry|
          next entry if entry.id

          row = record.queue_entries.create!(
            user_id: entry.profile_id,
            video_id: entry.video_id,
            position: entry.position,
            status: entry.status
          )
          copy = entry.dup
          copy.id = row.id
          copy
        end
        room.branch(entries: entries)
      end

      def update_state(room)
        record = @room
        record.update!(
          phase: room.phase,
          video_id: room.video_id,
          seed: room.seed,
          started_at_ms: room.started_at_ms,
          dj_id: room.dj_id,
          streak: room.streak,
          total_misses: room.total_misses,
          next_note_index: room.next_note_index,
          playback_ms: room.playback_ms
        )
        room.entries.each do |entry|
          next unless entry.id

          row = record.queue_entries.find(entry.id)
          row.update!(status: entry.status) if row.status != entry.status
        end
        room.judgements.each do |hit|
          Keypress.create!(
            room: record,
            queue_entry_id: room.judgement_entry_id,
            note_index: hit[:index],
            result: hit[:result]
          )
        end
        room.events.each { |name| append_event(name) }
      end

      def append_event(name)
        @room.outbox_messages.create!(event_name: name, payload: @payload.call.to_json)
      end

      def judgement(entry_id, note_index)
        return if entry_id.nil?

        Keypress.find_by(queue_entry_id: entry_id, note_index: note_index)&.result&.to_sym
      end

      def hits(entry_id)
        return [] if entry_id.nil?

        Keypress.where(queue_entry_id: entry_id).order(:note_index).map do |row|
          { index: row.note_index, result: row.result }
        end
      end

      def snapshot(room = @room)
        entry = room.queue_entries.find_by(user_id: room.dj_id, video_id: room.video_id, status: "playing")
        {
          phase: room.phase,
          video_id: room.video_id,
          seed: room.seed,
          started_at_ms: room.started_at_ms,
          playback_ms: room.playback_ms,
          dj_id: room.dj_id,
          dj_name: room.dj&.display_name,
          streak: room.streak,
          total_misses: room.total_misses,
          next_note_index: room.next_note_index,
          entry_id: entry&.id,
          queue: room.queue_entries.waiting.map { |item| { id: item.id, name: item.user.display_name, video_id: item.video_id } }
        }
      end

      private
        def entry_from(row)
          Booth::Entry.new(
            id: row.id,
            profile_id: row.user_id,
            profile_name: row.user.display_name,
            video_id: row.video_id,
            position: row.position,
            status: row.status
          )
        end
end
