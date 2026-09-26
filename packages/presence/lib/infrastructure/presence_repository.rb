class PresenceRepository
      def move_to(arrival, room_id:)
        rows = matches(arrival)
        left = rows.map(&:room_id).uniq - [ room_id ]
        rows.reject { |row| row.room_id == room_id }.each(&:destroy!)
        here = rows.select { |row| row.room_id == room_id }
        keeper = here.max_by { |row| row.user_id.present? ? 1 : 0 }
        (here - [ keeper ]).each(&:destroy!)

        if keeper
          keeper.update!(
            display_name: arrival.display_name,
            user_id: keeper.user_id || arrival.profile_id,
            guest_token: keeper.guest_token.presence || arrival.guest_token
          )
          changed = left.any? || keeper.saved_change_to_display_name? || keeper.saved_change_to_user_id? || keeper.saved_change_to_guest_token?
        else
          RoomPresence.create!(
            room_id: room_id,
            user_id: arrival.profile_id,
            guest_token: arrival.guest_token.presence,
            display_name: arrival.display_name,
            dancing: false
          )
          changed = true
        end

        [ changed, left ]
      end

      def people(room_id)
        RoomPresence.where(room_id: room_id).order(:display_name).map do |row|
          { name: row.display_name, dancing: row.dancing }
        end
      end

      def dance(room_id:, profile_id:, guest_token:)
        row = RoomPresence.find_by(room_id: room_id, user_id: profile_id) if profile_id
        row ||= RoomPresence.find_by(room_id: room_id, guest_token: guest_token) if guest_token.to_s != ""
        return if row.nil?

        row.update!(dancing: !row.dancing, user_id: row.user_id || profile_id)
        row
      end

      private
        def matches(arrival)
          parts = []
          parts << RoomPresence.where(user_id: arrival.profile_id) if arrival.profile_id
          parts << RoomPresence.where(guest_token: arrival.guest_token) if arrival.guest_token.to_s != ""
          return [] if parts.empty?

          parts.reduce { |scope, relation| scope.or(relation) }.to_a
        end
end
