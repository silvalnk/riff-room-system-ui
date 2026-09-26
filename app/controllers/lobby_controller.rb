class LobbyController < ApplicationController
  allow_unauthenticated_access

  def index
    @rooms = Room.catalog
  end
end
