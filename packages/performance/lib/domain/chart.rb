module Performance
  LETTERS = %w[A S D F G].freeze
  INTERVAL_MS = 800

  module Chart
    def self.letter_at(seed, index)
      LETTERS[(seed.to_i + index.to_i * 17) % LETTERS.length]
    end

    def self.due_at(started_at_ms, index)
      started_at_ms.to_i + index.to_i * INTERVAL_MS
    end
  end
end
