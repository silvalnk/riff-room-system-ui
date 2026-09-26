module Appreciation
  module Application
    class CastVote
      def call(profile_id:, direction:, entry_id:)
        notice = Ballot.new.cast(direction)
        return notice unless notice.ok?
        return Presence::Notice.new([ "account is required" ]) if profile_id.nil?
        return Presence::Notice.new([ "nothing is playing" ]) if entry_id.nil?

        Decision.new(profile_id: profile_id, entry_id: entry_id, direction: direction.to_s)
      end
    end
  end
end
