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

ActiveRecord::Schema[8.1].define(version: 2026_09_25_110000) do
  create_table "activities", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.json "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_activities_on_actor_id"
    t.index ["group_id", "created_at"], name: "index_activities_on_group_id_and_created_at"
    t.index ["group_id"], name: "index_activities_on_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "invite_code", null: false
    t.integer "member_limit", default: 20, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_code"], name: "index_groups_on_invite_code", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.integer "role", default: 0, null: false
    t.integer "total_points", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["group_id", "total_points"], name: "index_memberships_on_group_id_and_total_points"
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "participations", force: :cascade do |t|
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.boolean "finished", default: false, null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "points", default: 0, null: false
    t.integer "round_id", null: false
    t.integer "stage", default: 0, null: false
    t.integer "stage_reached"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["round_id"], name: "index_participations_on_round_id"
    t.index ["user_id", "round_id"], name: "index_participations_on_user_id_and_round_id", unique: true
    t.index ["user_id"], name: "index_participations_on_user_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.integer "song_id", null: false
    t.datetime "started_at", null: false
    t.integer "started_by_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_rounds_on_group_id"
    t.index ["group_id"], name: "index_rounds_one_active_per_group", unique: true, where: "status = 0"
    t.index ["song_id"], name: "index_rounds_on_song_id"
    t.index ["started_by_id"], name: "index_rounds_on_started_by_id"
  end

  create_table "scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.integer "total_points", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["group_id", "total_points"], name: "index_scores_on_group_id_and_total_points"
    t.index ["group_id"], name: "index_scores_on_group_id"
    t.index ["user_id", "group_id"], name: "index_scores_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_scores_on_user_id"
  end

  create_table "songs", force: :cascade do |t|
    t.integer "added_by_id", null: false
    t.string "artist", null: false
    t.string "audio_url", null: false
    t.datetime "created_at", null: false
    t.integer "group_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_songs_on_added_by_id"
    t.index ["group_id", "title", "artist"], name: "index_songs_on_group_id_and_title_and_artist", unique: true
    t.index ["group_id"], name: "index_songs_on_group_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "activities", "groups"
  add_foreign_key "activities", "users", column: "actor_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "participations", "rounds"
  add_foreign_key "participations", "users"
  add_foreign_key "rounds", "groups"
  add_foreign_key "rounds", "songs"
  add_foreign_key "rounds", "users", column: "started_by_id"
  add_foreign_key "scores", "groups"
  add_foreign_key "scores", "users"
  add_foreign_key "songs", "groups"
  add_foreign_key "songs", "users", column: "added_by_id"
end
