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

ActiveRecord::Schema.define(version: 20150513140356) do

  create_table "images", force: :cascade do |t|
    t.integer  "parent_id",     limit: 4
    t.string   "path",          limit: 255
    t.string   "filename",      limit: 255
    t.integer  "width",         limit: 4
    t.integer  "height",        limit: 4
    t.integer  "size",          limit: 4
    t.string   "mime_type",     limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.boolean  "has_galleries", limit: 1,   default: false
    t.boolean  "has_images",    limit: 1,   default: false
    t.string   "aws_thumb_url", limit: 255
    t.string   "aws_hdtv_url",  limit: 255
  end

end
