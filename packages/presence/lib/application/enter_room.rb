module Presence
  module Application
    class EnterRoom
      def call(profile_id:, guest_token:, display_name:)
        name = display_name.to_s.strip
        name = "Guest" if name.empty?
        Arrival.new(profile_id: profile_id, guest_token: guest_token, display_name: name)
      end
    end
  end
end
