# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171011155552) do

  create_table "authors", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bd_auteurs", primary_key: "aid", force: :cascade do |t|
    t.string "nom", limit: 50, default: "", null: false
  end

  create_table "bd_bd", primary_key: "bdid", force: :cascade do |t|
    t.integer "sid", limit: 3, default: 0, null: false
    t.string "titre", limit: 100, default: "", null: false
    t.integer "numero", limit: 2, default: 0, null: false
    t.integer "datedajout", default: 1198486315, null: false
    t.integer "par", limit: 3, default: 0, null: false
    t.integer "PID1", limit: 1, default: 0, null: false
    t.integer "PID2", limit: 1, default: 0, null: false
    t.integer "PID9", limit: 1, default: 0, null: false
    t.integer "PID23", limit: 1, default: 0, null: false
  end

  create_table "bd_bdaid", force: :cascade do |t|
    t.integer "bdid", null: false
    t.integer "aid", null: false
    t.index ["bdid", "aid"], name: "bdid"
    t.index ["id"], name: "id", unique: true
  end

  create_table "bd_membres", primary_key: "pid", force: :cascade do |t|
    t.string "cle", limit: 32, default: "", null: false
    t.string "login", limit: 30, default: "", null: false
    t.string "password", limit: 35, default: "", null: false
    t.string "nom", limit: 70, default: "", null: false
    t.text "amis", limit: 16777215, null: false
    t.boolean "admin", default: false, null: false
  end

  create_table "bd_prets", force: :cascade do |t|
    t.integer "bdid", null: false
    t.string "texte", null: false
    t.datetime "date", null: false
    t.integer "pid", null: false
  end

  create_table "bd_series", primary_key: "sid", force: :cascade do |t|
    t.string "nom", limit: 50, default: "", null: false
    t.string "lettre", limit: 1, default: "", null: false
    t.integer "PID1", limit: 1, default: 0, null: false
    t.integer "PID2", limit: 1, default: 0, null: false
    t.integer "PID9", limit: 1, default: 0, null: false
    t.integer "PID23", limit: 1, default: 0, null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "default_view"
  end

  create_table "comments", force: :cascade do |t|
    t.text "message"
    t.integer "post_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "itemauthors", force: :cascade do |t|
    t.integer "author_id"
    t.integer "item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_itemauthors_on_author_id"
    t.index ["item_id"], name: "index_itemauthors_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "numero"
    t.string "name"
    t.integer "series_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "adder_id"
  end

  create_table "itemusers", force: :cascade do |t|
    t.integer "item_id"
    t.integer "user_id"
    t.integer "quantity"
    t.datetime "checked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "likes", force: :cascade do |t|
    t.integer "item_id"
    t.integer "user_id"
    t.integer "note"
    t.string "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_likes_on_item_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "message"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "series", force: :cascade do |t|
    t.string "name"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "letter"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.string "votable_type"
    t.integer "votable_id"
    t.string "voter_type"
    t.integer "voter_id"
    t.boolean "vote_flag"
    t.string "vote_scope"
    t.integer "vote_weight"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope"
    t.index ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope"
  end

end
