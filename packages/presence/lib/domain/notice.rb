module Presence
  class Notice
    attr_reader :errors

    def initialize(errors = [])
      @errors = Array(errors)
    end

    def ok?
      errors.empty?
    end
  end

  Arrival = Struct.new(:profile_id, :guest_token, :display_name, keyword_init: true)
end
