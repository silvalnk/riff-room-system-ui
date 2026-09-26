class CreateRoomTables < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :phase, null: false, default: "idle"
      t.string :video_id
      t.integer :seed
      t.integer :started_at_ms
      t.references :dj, foreign_key: { to_table: :users }
      t.integer :streak, null: false, default: 0
      t.integer :total_misses, null: false, default: 0
      t.integer :next_note_index, null: false, default: 0
      t.integer :playback_ms, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    create_table :queue_entries do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :video_id, null: false
      t.integer :position, null: false
      t.string :status, null: false, default: "waiting"
      t.timestamps
    end
    add_index :queue_entries, [ :room_id, :position ]

    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :queue_entry, null: false, foreign_key: true
      t.string :direction, null: false
      t.timestamps
    end
    add_index :votes, [ :user_id, :queue_entry_id ], unique: true

    create_table :keypresses do |t|
      t.references :room, null: false, foreign_key: true
      t.references :queue_entry, null: false, foreign_key: true
      t.integer :note_index, null: false
      t.string :result, null: false
      t.timestamps
    end
    add_index :keypresses, [ :queue_entry_id, :note_index ], unique: true

    create_table :outbox_messages do |t|
      t.references :room, null: false, foreign_key: true
      t.string :event_name, null: false
      t.text :payload, null: false
      t.datetime :published_at
      t.timestamps
    end

    create_table :room_presences do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :guest_token
      t.string :display_name, null: false
      t.timestamps
    end
  end
end
