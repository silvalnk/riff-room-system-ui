module Performance
  class FailurePolicy
    STREAK_LIMIT = 3
    TOTAL_LIMIT = 8

    def failed?(streak:, total:)
      streak.to_i >= STREAK_LIMIT || total.to_i >= TOTAL_LIMIT
    end
  end
end
