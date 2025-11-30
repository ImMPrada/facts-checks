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

ActiveRecord::Schema[8.1].define(version: 2025_11_29_194910) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "fact_check_urls", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "digested", default: false, null: false
    t.datetime "digested_at"
    t.text "last_error"
    t.integer "source", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["digested"], name: "index_fact_check_urls_on_digested"
    t.index ["source", "digested"], name: "index_fact_check_urls_on_source_and_digested"
    t.index ["url"], name: "index_fact_check_urls_on_url", unique: true
  end

  create_table "fact_checks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "digested", default: false
    t.bigint "publication_date_id"
    t.text "reasoning"
    t.string "source_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "veredict_id", null: false
    t.index ["publication_date_id"], name: "index_fact_checks_on_publication_date_id"
    t.index ["veredict_id"], name: "index_fact_checks_on_veredict_id"
  end

  create_table "publication_dates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "date"
    t.datetime "updated_at", null: false
    t.date "value"
    t.index ["date"], name: "index_publication_dates_on_date", unique: true
    t.index ["value"], name: "index_publication_dates_on_value"
  end

  create_table "veredicts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_veredicts_on_name", unique: true
  end

  add_foreign_key "fact_checks", "publication_dates"
  add_foreign_key "fact_checks", "veredicts"
end
