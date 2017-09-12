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

ActiveRecord::Schema.define(version: 20_170_821_214_046) do
  create_table 'comments', force: :cascade do |t|
    t.integer  'topic_id'
    t.integer  'author_id'
    t.string   'title'
    t.string   'comment'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['author_id'], name: 'index_comments_on_author_id'
    t.index ['topic_id'], name: 'index_comments_on_topic_id'
  end

  create_table 'publishers', force: :cascade do |t|
    t.string   'name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'topics', force: :cascade do |t|
    t.string   'character'
    t.string   'book'
    t.string   'quote'
    t.string   'location'
    t.date     'published'
    t.string   'author'
    t.datetime 'created_at',   null: false
    t.datetime 'updated_at',   null: false
    t.integer  'publisher_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string   'email'
    t.string   'first_name'
    t.string   'last_name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end
end
