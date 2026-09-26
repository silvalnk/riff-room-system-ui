module Booth
  class YoutubeUrl
    PATTERNS = [
      %r{youtu\.be/([\w-]{11})},
      %r{youtube\.com/(?:watch\?v=|embed/|shorts/)([\w-]{11})},
      /\A([\w-]{11})\z/
    ].freeze

    def self.extract(raw)
      text = raw.to_s.strip
      PATTERNS.each do |pattern|
        match = text.match(pattern)
        return match[1] if match
      end
      nil
    end
  end
end
