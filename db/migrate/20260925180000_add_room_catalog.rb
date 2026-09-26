class AddRoomCatalog < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :name, :string, null: false, default: "Sala"
    add_column :rooms, :slug, :string
    add_column :rooms, :blurb, :string
    add_index :rooms, :slug, unique: true
  end
end
