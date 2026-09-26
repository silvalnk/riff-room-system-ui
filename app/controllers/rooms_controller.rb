class RoomsController < ApplicationController
  allow_unauthenticated_access only: %i[show enter interrupt dance]
  before_action :set_room

  def show
    token = cookies.signed[:guest_token]
    gateway.enter(user: Current.user, guest_token: token, display_name: "Guest") if Current.user || token.present?
    @snapshot = gateway.snapshot
    @mine = gateway.viewer_direction(Current.user, @snapshot[:entry_id])
  end

  def enter
    token = cookies.signed[:guest_token] ||= SecureRandom.hex(16)
    notice = gateway.enter(user: Current.user, guest_token: token, display_name: "Guest")
    redirect_to @room, alert: notice.errors.join(", ") and return unless notice.ok?

    redirect_to @room, notice: "Você entrou na sala."
  end

  def enqueue
    notice = gateway.enqueue(Current.user, params[:url])
    redirect_to @room, alert: notice.errors.join(", ") and return unless notice.ok?

    patch_room
  end

  def vote
    notice = gateway.vote(Current.user, params[:direction])
    redirect_to @room, alert: notice.errors.join(", ") and return unless notice.ok?

    patch_room
  end

  def dance
    token = cookies.signed[:guest_token] ||= SecureRandom.hex(16)
    notice = gateway.dance(user: Current.user, guest_token: token)
    redirect_to @room, alert: notice.errors.join(", ") and return unless notice.ok?

    patch_room
  end

  def press
    outcome = gateway.press(
      Current.user,
      letter: params[:letter],
      note_index: params[:note_index].to_i,
      now_ms: params[:now_ms].to_i
    )
    render json: outcome
  end

  def interrupt
    notice = gateway.interrupt(params[:reason])
    render json: { ok: notice.ok?, errors: notice.errors }
  end

  def sync
    gateway.sync(Current.user, params[:playback_ms])
    head :no_content
  end

  private
    def set_room
      @room = Room.catalog.find_by!(slug: params[:slug] || params[:room_slug])
    end

    def gateway
      @gateway ||= RoomGateway.new(@room)
    end

    def patch_room
      @snapshot = gateway.snapshot
      respond_to do |format|
        format.turbo_stream { render "rooms/refresh" }
        format.html { redirect_to @room }
      end
    end
end
