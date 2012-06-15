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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120525232123) do

  create_table "vivi_albumings", :force => true do |t|
    t.integer  "vivi_album_id"
    t.integer  "vivi_doc_id"
    t.integer  "position"
    t.integer  "submitted_by"
    t.datetime "submitted_at"
    t.boolean  "approved",       :default => false
    t.integer  "approved_by"
    t.datetime "approved_at"
    t.text     "approval_notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_albumings", ["vivi_doc_id", "vivi_album_id"], :name => "index_vivi_albumings_on_doc_id_and_album_id"
  add_index "vivi_albumings", ["submitted_by", "submitted_at"], :name => "index_vivi_albumings_on_submitted_by_and_submitted_at"

  create_table "vivi_albums", :force => true do |t|
    t.string   "name",                          :default => ""
    t.text     "description"
    t.string   "type",            :limit => 64, :default => ""
    t.integer  "created_by"
    t.string   "status",                        :default => "publish"
    t.string   "submission_priv",               :default => "open"
    t.string   "view_priv",                     :default => "public"
    t.boolean  "promoted",                      :default => false
    t.integer  "promoted_by"
    t.datetime "promoted_at"
    t.string   "uuid",                          :default => "",        :null => false
    t.integer  "ext_ref"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_albums", ["created_by", "updated_at"], :name => "index_vivi_albums_on_created_by_and_updated_at"

  create_table "vivi_creatorings", :force => true do |t|
    t.integer  "vivi_metadata_id"
    t.integer  "vivi_creator_id"
    t.integer  "position",         :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_creatorings", ["vivi_creator_id", "vivi_metadata_id"], :name => "index_vivi_creatorings_on_creator_id_and_metadata_id"

  create_table "vivi_creators", :force => true do |t|
    t.string   "name",                         :default => ""
    t.string   "culture",       :limit => 128, :default => ""
    t.string   "role",          :limit => 128, :default => ""
    t.date     "born_at"
    t.date     "died_at"
    t.string   "add_attr",                     :default => ""
    t.string   "aka",                          :default => ""
    t.string   "education",                    :default => ""
    t.string   "movement",                     :default => ""
    t.string   "reference_url",                :default => ""
    t.text     "notes"
    t.string   "uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_creators", ["name"], :name => "index_vivi_creators_on_name"

  create_table "vivi_delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_delayed_jobs", ["priority", "run_at"], :name => "vivi_delayed_jobs_priority"

  create_table "vivi_docs", :force => true do |t|
    t.string   "title",              :default => ""
    t.string   "asset_file_name",    :default => ""
    t.string   "asset_content_type", :default => ""
    t.integer  "asset_file_size"
    t.datetime "asset_updated_at"
    t.string   "asset_resolution",   :default => ""
    t.integer  "asset_dpi",          :default => 0
    t.string   "asset_remote_url",   :default => ""
    t.boolean  "processing",         :default => true
    t.integer  "views",              :default => 0
    t.integer  "created_by"
    t.string   "uuid",               :default => "",   :null => false
    t.integer  "ext_ref"
    t.string   "cover",              :default => ""
    t.integer  "poster_for"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_docs", ["created_by", "created_at"], :name => "index_vivi_docs_on_created_by_and_created_at"

  create_table "vivi_metadatas", :force => true do |t|
    t.integer  "vivi_doc_id"
    t.text     "description"
    t.string   "culture",           :limit => 128, :default => ""
    t.date     "creation_start_at"
    t.date     "creation_end_at"
    t.string   "current_location",  :limit => 128, :default => ""
    t.string   "medium",            :limit => 128, :default => ""
    t.string   "dimensions",        :limit => 32,  :default => ""
    t.string   "period_style",      :limit => 128, :default => ""
    t.string   "language",          :limit => 64,  :default => ""
    t.string   "source",            :limit => 64,  :default => ""
    t.string   "digitization_spec",                :default => ""
    t.text     "subject_headings"
    t.string   "subject_matter",                   :default => ""
    t.string   "type_of_work",                     :default => ""
    t.string   "media_credits",                    :default => ""
    t.string   "caption",                          :default => ""
    t.integer  "vivi_right_id"
    t.string   "publish_status",                   :default => "local-only"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vivi_metadatas", ["vivi_doc_id"], :name => "index_vivi_metadatas_on_doc_id"
  add_index "vivi_metadatas", ["vivi_right_id"], :name => "index_vivi_metadatas_on_right_id"

  create_table "vivi_rights", :force => true do |t|
    t.string  "name",     :default => ""
    t.boolean "cc",       :default => false
    t.string  "ext_link", :default => ""
  end

end
