# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150521160540) do

  create_table "images", force: :cascade do |t|
    t.integer  "parent_id",     limit: 4
    t.string   "path",          limit: 255
    t.string   "filename",      limit: 255
    t.integer  "width",         limit: 4
    t.integer  "height",        limit: 4
    t.integer  "size",          limit: 4
    t.string   "mime_type",     limit: 255
    t.boolean  "has_galleries", limit: 1,   default: false
    t.boolean  "has_images",    limit: 1,   default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "aws_thumb_url", limit: 255
    t.string   "aws_hdtv_url",  limit: 255
    t.string   "uid",           limit: 255,                 null: false
  end

  add_index "images", ["uid"], name: "index_images_on_uid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                         limit: 255,  default: "", null: false
    t.string   "email",                        limit: 255,               null: false
    t.string   "encrypted_password",           limit: 255,               null: false
    t.string   "password_salt",                limit: 255,               null: false
    t.string   "confirmation_token",           limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token",         limit: 255
    t.datetime "reset_password_token_sent_at"
    t.integer  "failed_attempts",              limit: 4
    t.string   "unlock_token",                 limit: 255
    t.datetime "locked_at"
    t.string   "tokens",                       limit: 1024
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

end
