require "rails_helper"

RSpec.describe Performance::HitWindow do
  it "accepts the expected letter inside the window" do
    expect(described_class.judge(expected: "A", pressed: "a", due_ms: 1_000, now_ms: 1_200)).to eq(:hit)
  end

  it "rejects a wrong letter and a late press" do
    expect(described_class.judge(expected: "A", pressed: "S", due_ms: 1_000, now_ms: 1_000)).to eq(:miss)
    expect(described_class.judge(expected: "A", pressed: "A", due_ms: 1_000, now_ms: 1_500)).to eq(:miss)
  end
end

RSpec.describe Performance::Chart do
  it "repeats the same letter for the same seed and index" do
    expect(described_class.letter_at(4, 3)).to eq(described_class.letter_at(4, 3))
    expect(Performance::LETTERS).to include(described_class.letter_at(4, 3))
  end
end

RSpec.describe Performance::FailurePolicy do
  it "fails on three misses in a row or eight in the turn" do
    policy = described_class.new
    expect(policy.failed?(streak: 3, total: 3)).to be(true)
    expect(policy.failed?(streak: 1, total: 8)).to be(true)
    expect(policy.failed?(streak: 2, total: 7)).to be(false)
  end
end

RSpec.describe Booth::YoutubeUrl do
  it "keeps only the video id" do
    expect(described_class.extract("https://www.youtube.com/watch?v=dQw4w9WgXcQ")).to eq("dQw4w9WgXcQ")
    expect(described_class.extract("https://youtu.be/dQw4w9WgXcQ")).to eq("dQw4w9WgXcQ")
    expect(described_class.extract("not a video")).to be_nil
  end
end

RSpec.describe Booth::Aggregate do
  let(:state) { { seed: 1, started_at_ms: 0, streak: 2, total_misses: 2, next_note_index: 0 } }

  it "fails when the third miss lands" do
    letter = Performance::Chart.letter_at(1, 0)
    outcome = described_class.press(state, letter: "Z", note_index: 0, now_ms: 0, already_judged: nil)
    expect(outcome[:result]).to eq(:miss)
    expect(outcome[:failed]).to be(true)
  end

  it "returns the earlier result for the same note" do
    outcome = described_class.press(state, letter: "A", note_index: 0, now_ms: 0, already_judged: :hit)
    expect(outcome[:result]).to eq(:hit)
    expect(outcome[:failed]).to be(false)
  end
end
