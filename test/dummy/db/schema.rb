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

ActiveRecord::Schema[7.1].define(version: 2025_08_07_231658) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bloggity_blog_assets", force: :cascade do |t|
    t.integer "blog_post_id"
    t.integer "parent_id"
    t.string "content_type"
    t.string "filename"
    t.string "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bloggity_blog_categories", force: :cascade do |t|
    t.string "name"
    t.integer "parent_id"
    t.integer "group_id", default: 0
    t.integer "blog_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_bloggity_blog_categories_on_group_id"
    t.index ["parent_id"], name: "index_bloggity_blog_categories_on_parent_id"
  end

  create_table "bloggity_blog_comments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "blog_post_id"
    t.text "comment"
    t.boolean "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bloggity_blog_posts", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.string "tag_string"
    t.integer "posted_by_id"
    t.boolean "is_complete"
    t.string "url_identifier"
    t.boolean "comments_closed"
    t.integer "category_id"
    t.integer "blog_id", default: 1
    t.boolean "fck_created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bloggity_blog_tags", force: :cascade do |t|
    t.string "name"
    t.integer "blog_post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bloggity_blogs", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "url_identifier"
    t.string "stylesheet"
    t.string "feedburner_url"
    t.integer "category_id"
    t.boolean "fck_created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_bloggity_blogs_on_category_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
