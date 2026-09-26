module Appreciation
  class Ballot
    DIRECTIONS = %w[up down].freeze

    def cast(direction)
      return Presence::Notice.new([ "direction is invalid" ]) unless DIRECTIONS.include?(direction.to_s)

      Presence::Notice.new
    end
  end

  Decision = Struct.new(:profile_id, :entry_id, :direction, keyword_init: true)
end
