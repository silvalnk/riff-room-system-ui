module Performance
  module HitWindow
    WINDOW_MS = 400

    def self.judge(expected:, pressed:, due_ms:, now_ms:)
      return :miss unless same?(expected, pressed)
      return :miss if (now_ms.to_i - due_ms.to_i).abs > WINDOW_MS

      :hit
    end

    def self.same?(expected, pressed)
      return false if pressed.nil? || pressed.to_s.empty?
      return pressed.to_s == ";" if expected == ";"

      expected.to_s.casecmp?(pressed.to_s)
    end
  end
end
