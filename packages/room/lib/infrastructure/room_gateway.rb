class RoomGateway
  def initialize(room)
    @room = room
  end

  def snapshot
    state = booth.snapshot
    last_event = @room.outbox_messages.order(id: :desc).pick(:event_name)
    failed_name = failed_dj_name if last_event == "TurnFailed"
    state.merge(votes.tally(state[:entry_id])).merge(
      listeners: presence.people(@room.id),
      hits: booth.hits(state[:entry_id]),
      last_event: last_event,
      failed_name: failed_name,
      server_now_ms: (Time.current.to_f * 1000).to_i,
      name: @room.name,
      slug: @room.slug
    )
  end

  def viewer_direction(user, entry_id)
    votes.direction_for(user&.id, entry_id)
  end

  def enter(user: nil, guest_token: nil, display_name: nil)
    arrival = Presence::Application::EnterRoom.new.call(
      profile_id: user&.id,
      guest_token: guest_token,
      display_name: user&.display_name || display_name
    )
    return Presence::Notice.new if arrival.profile_id.nil? && arrival.guest_token.blank?

    changed, left = presence.move_to(arrival, room_id: @room.id)
    announce_presence(left) if changed
    Presence::Notice.new
  end

  def dance(user: nil, guest_token: nil)
    return Presence::Notice.new([ "nada está tocando" ]) unless booth.load.playing?

    danced = presence.dance(room_id: @room.id, profile_id: user&.id, guest_token: guest_token)
    if danced.nil?
      enter(user: user, guest_token: guest_token, display_name: user&.display_name || "Guest")
      danced = presence.dance(room_id: @room.id, profile_id: user&.id, guest_token: guest_token)
    end
    return Presence::Notice.new([ "entre na sala primeiro" ]) if danced.nil?

    booth.append_event("Dance")
    publish!
    Presence::Notice.new
  end

  def enqueue(user, raw_url)
    finish Booth::Application::EnqueueSong.new(repository: booth, clock: clock, seeds: seeds).call(
      profile_id: user&.id,
      profile_name: user&.display_name,
      raw_url: raw_url
    )
  end

  def vote(user, direction)
    notice = booth.transaction do
      room = booth.load
      next Presence::Notice.new([ "nada está tocando" ]) unless room.playing?

      outcome = Appreciation::Application::CastVote.new.call(
        profile_id: user&.id,
        direction: direction,
        entry_id: room.playing_entry&.id
      )
      next outcome if outcome.is_a?(Presence::Notice)

      votes.record(outcome)
      booth.append_event("VoteCast")
      Presence::Notice.new
    end
    finish notice == :stale ? Presence::Notice.new([ "room changed, retry" ]) : notice
  end

  def press(user, letter:, note_index:, now_ms:)
    outcome = Booth::Application::PressKey.new(repository: booth, clock: clock, seeds: seeds).call(
      profile_id: user&.id,
      letter: letter,
      note_index: note_index,
      now_ms: now_ms
    )
    publish! if outcome.is_a?(Hash) && outcome[:result] != :ignored
    outcome
  rescue ActiveRecord::RecordNotUnique
    { result: :miss }
  end

  def interrupt(reason)
    finish Booth::Application::InterruptTurn.new(repository: booth, clock: clock, seeds: seeds).call(reason: reason)
  end

  def sync(user, playback_ms)
    finish Booth::Application::SyncPlayback.new(repository: booth).call(profile_id: user&.id, playback_ms: playback_ms)
  end

  def publish!
    @room.outbox_messages.unpublished.find_each do |message|
      broadcast_room!
      message.update!(published_at: Time.current)
    end
  end

  def publish_floor!
    state = snapshot
    Turbo::StreamsChannel.broadcast_replace_to("room-#{@room.id}", target: "room_floor", partial: "rooms/floor", locals: { snapshot: state })
  end

  private
    def booth
      @booth ||= RoomRepository.new(room: @room, payload: -> { snapshot })
    end

    def votes
      @votes ||= VoteRepository.new
    end

    def presence
      @presence ||= PresenceRepository.new
    end

    def clock
      -> { (Time.current.to_f * 1000).to_i }
    end

    def seeds
      ->(entry) { Random.new(entry.id + entry.position).rand(1..9_999) }
    end

    def failed_dj_name
      @room.queue_entries.where(status: "failed").order(updated_at: :desc).first&.user&.display_name
    end

    def announce_presence(left_ids)
      publish_floor!
      left_ids.each do |room_id|
        other = Room.find_by(id: room_id)
        RoomGateway.new(other).publish_floor! if other
      end
    end

    def broadcast_room!
      state = snapshot
      Turbo::StreamsChannel.broadcast_replace_to("room-#{@room.id}", target: "room_state", partial: "rooms/state", locals: { snapshot: state })
      Turbo::StreamsChannel.broadcast_replace_to("room-#{@room.id}", target: "room_chrome", partial: "rooms/chrome", locals: { snapshot: state })
      Turbo::StreamsChannel.broadcast_replace_to("room-#{@room.id}", target: "room_floor", partial: "rooms/floor", locals: { snapshot: state })
    end

    def finish(notice)
      publish! if notice.respond_to?(:ok?) && notice.ok?
      notice
    end
end
