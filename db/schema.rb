# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_25_183000) do
  create_table "keypresses", force: :cascade do |t|
    t.integer "room_id", null: false
    t.integer "queue_entry_id", null: false
    t.integer "note_index", null: false
    t.string "result", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_entry_id", "note_index"], name: "index_keypresses_on_queue_entry_id_and_note_index", unique: true
    t.index ["queue_entry_id"], name: "index_keypresses_on_queue_entry_id"
    t.index ["room_id"], name: "index_keypresses_on_room_id"
  end

  create_table "outbox_messages", force: :cascade do |t|
    t.integer "room_id", null: false
    t.string "event_name", null: false
    t.text "payload", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_outbox_messages_on_room_id"
  end

  create_table "queue_entries", force: :cascade do |t|
    t.integer "room_id", null: false
    t.integer "user_id", null: false
    t.string "video_id", null: false
    t.integer "position", null: false
    t.string "status", default: "waiting", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "position"], name: "index_queue_entries_on_room_id_and_position"
    t.index ["room_id"], name: "index_queue_entries_on_room_id"
    t.index ["user_id"], name: "index_queue_entries_on_user_id"
  end

  create_table "room_presences", force: :cascade do |t|
    t.integer "room_id", null: false
    t.integer "user_id"
    t.string "guest_token"
    t.string "display_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "dancing", default: false, null: false
    t.index ["room_id"], name: "index_room_presences_on_room_id"
    t.index ["user_id"], name: "index_room_presences_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "phase", default: "idle", null: false
    t.string "video_id"
    t.integer "seed"
    t.integer "started_at_ms"
    t.integer "dj_id"
    t.integer "streak", default: 0, null: false
    t.integer "total_misses", default: 0, null: false
    t.integer "next_note_index", default: 0, null: false
    t.integer "playback_ms", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "Sala", null: false
    t.string "slug"
    t.string "blurb"
    t.index ["dj_id"], name: "index_rooms_on_dj_id"
    t.index ["slug"], name: "index_rooms_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "display_name", default: "Listener", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "queue_entry_id", null: false
    t.string "direction", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_entry_id"], name: "index_votes_on_queue_entry_id"
    t.index ["user_id", "queue_entry_id"], name: "index_votes_on_user_id_and_queue_entry_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "keypresses", "queue_entries"
  add_foreign_key "keypresses", "rooms"
  add_foreign_key "outbox_messages", "rooms"
  add_foreign_key "queue_entries", "rooms"
  add_foreign_key "queue_entries", "users"
  add_foreign_key "room_presences", "rooms"
  add_foreign_key "room_presences", "users"
  add_foreign_key "rooms", "users", column: "dj_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "votes", "queue_entries"
  add_foreign_key "votes", "users"
end
