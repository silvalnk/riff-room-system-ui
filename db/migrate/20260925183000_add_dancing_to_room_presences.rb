class AddDancingToRoomPresences < ActiveRecord::Migration[8.1]
  def change
    add_column :room_presences, :dancing, :boolean, null: false, default: false
  end
end
