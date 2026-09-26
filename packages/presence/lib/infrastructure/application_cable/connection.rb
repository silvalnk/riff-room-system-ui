module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :guest_token

    def connect
      self.current_user = Session.find_by(id: cookies.signed[:session_id])&.user
      self.guest_token = cookies.signed[:guest_token].presence || "listener"
    end
  end
end
