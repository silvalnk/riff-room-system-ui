require "rails_helper"

RSpec.describe RoomGateway do
  let(:room) { Room.create!(name: "Spec", slug: "spec", blurb: "Sala de teste") }
  let(:gateway) { described_class.new(room) }
  let(:dj) { User.create!(display_name: "Ada", email_address: "ada@example.com", password: "secret123") }
  let(:listener) { User.create!(display_name: "Gus", email_address: "gus@example.com", password: "secret123") }

  it "refuses vote and dance while the room is idle" do
    expect(gateway.vote(listener, "up")).not_to be_ok
    expect(gateway.dance(user: listener, guest_token: "gus")).not_to be_ok
    expect(RoomPresence.where(dancing: true)).to be_none
  end

  it "keeps a person in one room and tells both rooms" do
    other = Room.create!(name: "Other", slug: "other-floor", blurb: "Outra sala")
    expect {
      gateway.enter(user: listener, guest_token: "gus", display_name: listener.display_name)
    }.to have_broadcasted_to("room-#{room.id}")

    expect {
      described_class.new(other).enter(user: listener, guest_token: "gus", display_name: listener.display_name)
    }.to have_broadcasted_to("room-#{room.id}").and have_broadcasted_to("room-#{other.id}")

    expect(RoomPresence.where(room_id: room.id, user: listener)).to be_empty
    expect(RoomPresence.where(room_id: other.id, user: listener).count).to eq(1)

    expect {
      described_class.new(other).enter(user: listener, guest_token: "gus", display_name: listener.display_name)
    }.not_to have_broadcasted_to("room-#{other.id}")
  end

  it "hands the booth to the next person after three misses and keeps a vote from skipping" do
    expect(gateway.enqueue(nil, "https://youtu.be/dQw4w9WgXcQ")).not_to be_ok
    expect(gateway.enqueue(dj, "https://youtu.be/dQw4w9WgXcQ")).to be_ok
    expect(gateway.enqueue(listener, "https://youtu.be/jNQXAC9IVRw")).to be_ok

    room = Room.find_by!(slug: "spec")
    started = room.started_at_ms
    expect(room.dj).to eq(dj)
    entry = room.queue_entries.find_by(status: "playing")
    expect(gateway.vote(listener, "down")).to be_ok
    expect(room.reload.dj).to eq(dj)
    expect(room.video_id).to eq("dQw4w9WgXcQ")
    expect(room.started_at_ms).to eq(started)
    expect(Vote.where(queue_entry: entry, direction: "down").count).to eq(1)
    expect(gateway.vote(listener, "up")).to be_ok
    expect(Vote.where(queue_entry: entry).count).to eq(1)
    expect(gateway.enter(user: listener, guest_token: "gus", display_name: listener.display_name)).to be_ok
    expect(gateway.dance(user: listener)).to be_ok
    expect(room.reload.video_id).to eq("dQw4w9WgXcQ")
    expect(room.started_at_ms).to eq(started)
    expect(room.phase).to eq("playing")
    expect(gateway.snapshot[:listeners]).to include(a_hash_including(name: "Gus", dancing: true))
    expect(gateway.snapshot[:server_now_ms]).to be_within(5_000).of((Time.current.to_f * 1000).to_i)

    3.times do |index|
      due = room.started_at_ms + index * Performance::INTERVAL_MS
      gateway.press(dj, letter: "Z", note_index: index, now_ms: due)
    end

    expect(room.reload.dj).to eq(listener)
    expect(room.video_id).to eq("jNQXAC9IVRw")
  end
end
