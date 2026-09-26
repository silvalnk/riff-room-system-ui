class VoteRepository
      def record(decision)
        Vote.find_or_initialize_by(user_id: decision.profile_id, queue_entry_id: decision.entry_id).update!(direction: decision.direction)
      end

      def tally(entry_id)
        return { ups: 0, downs: 0 } if entry_id.nil?

        counts = Vote.where(queue_entry_id: entry_id).group(:direction).count
        { ups: counts["up"].to_i, downs: counts["down"].to_i }
      end

      def direction_for(profile_id, entry_id)
        return if profile_id.nil? || entry_id.nil?

        Vote.find_by(user_id: profile_id, queue_entry_id: entry_id)&.direction
      end
end
