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

ActiveRecord::Schema.define(:version => 20110215194613) do

  create_table "addresses", :force => true do |t|
    t.integer  "routematch_address_id"
    t.string   "common_name"
    t.string   "building_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "postal_code"
    t.string   "x_coordinate"
    t.string   "y_coordinate"
    t.boolean  "in_trimet_district"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "allocations", :force => true do |t|
    t.string  "name"
    t.boolean "group_trip"
    t.integer "project_id"
    t.integer "provider_id"
    t.string  "county"
    t.string  "trip_collection_method"
    t.string  "run_collection_method"
    t.string  "cost_collection_method"
    t.string  "routematch_override"
    t.string  "routematch_provider_code"
  end

  create_table "customers", :force => true do |t|
    t.integer  "routematch_customer_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "middle_initial"
    t.string   "sex"
    t.string   "race"
    t.string   "mobility"
    t.string   "telephone_primary"
    t.string   "telephone_primary_extension"
    t.string   "telephone_secondary"
    t.string   "telephone_secondary_extension"
    t.string   "language_preference"
    t.date     "birthdate"
    t.string   "email"
    t.string   "customer_type"
    t.integer  "monthly_household_income"
    t.integer  "household_size"
    t.integer  "address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "funding_source"
    t.string   "funding_subsource"
    t.string   "project_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "providers", :force => true do |t|
    t.string   "name",          :limit => 50
    t.string   "provider_type", :limit => 15
    t.string   "agency",        :limit => 50
    t.string   "branch",        :limit => 50
    t.string   "subcontractor", :limit => 50
    t.string   "routematch_id", :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "runs", :id => false, :force => true do |t|
    t.string   "id",             :limit => 36,                    :null => false
    t.string   "base_id",        :limit => 36
    t.datetime "valid_start"
    t.datetime "valid_end"
    t.date     "date"
    t.string   "name"
    t.integer  "routematch_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "odometer_start"
    t.integer  "odometer_end"
    t.integer  "escort_count"
    t.integer  "trip_import_id"
    t.integer  "updated_by"
    t.boolean  "complete",                     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "imported_at"
  end

  add_index "runs", ["base_id"], :name => "runs_base_id_idx"
  add_index "runs", ["date"], :name => "runs_date_idx"
  add_index "runs", ["valid_end"], :name => "runs_valid_end_idx"
  add_index "runs", ["valid_start"], :name => "runs_valid_start_idx"

  create_table "summaries", :id => false, :force => true do |t|
    t.string   "id",                             :limit => 36,                                                   :null => false
    t.string   "base_id",                        :limit => 36
    t.datetime "valid_start"
    t.datetime "valid_end"
    t.date     "period_start"
    t.date     "period_end"
    t.integer  "total_miles"
    t.integer  "driver_hours_paid"
    t.integer  "driver_hours_volunteer"
    t.integer  "escort_hours_volunteer"
    t.integer  "administrative_hours_volunteer"
    t.integer  "unduplicated_riders"
    t.integer  "turn_downs"
    t.decimal  "agency_other",                                 :precision => 10, :scale => 2
    t.decimal  "donations",                                    :precision => 10, :scale => 2
    t.decimal  "funds",                                        :precision => 10, :scale => 2
    t.integer  "allocation_id"
    t.integer  "updated_by"
    t.boolean  "complete",                                                                    :default => false
    t.integer  "administrative"
    t.integer  "operations"
    t.integer  "vehicle_maint"
  end

  create_table "summary_rows", :id => false, :force => true do |t|
    t.string   "id",                    :limit => 36, :null => false
    t.string   "base_id",               :limit => 36
    t.datetime "valid_start"
    t.datetime "valid_end"
    t.string   "purpose"
    t.integer  "in_district_trips"
    t.string   "summary_id"
    t.integer  "updated_by"
    t.integer  "out_of_district_trips"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "trip_imports", :force => true do |t|
    t.string   "file_path"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "trips", :id => false, :force => true do |t|
    t.string   "id",                               :limit => 36,                                :null => false
    t.string   "base_id",                          :limit => 36
    t.datetime "valid_start"
    t.datetime "valid_end"
    t.date     "date"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "odometer_start"
    t.integer  "odometer_end"
    t.decimal  "fare",                                           :precision => 10, :scale => 2
    t.string   "purpose_type"
    t.integer  "guest_count"
    t.integer  "attendant_count"
    t.string   "mobility"
    t.decimal  "calculated_bpa_fare",                            :precision => 10, :scale => 2
    t.string   "bpa_driver_name"
    t.boolean  "volunteer_trip"
    t.boolean  "in_trimet_district"
    t.float    "bpa_billing_distance"
    t.integer  "routematch_share_id"
    t.string   "override"
    t.float    "estimated_trip_distance_in_miles"
    t.integer  "pickup_address_id"
    t.integer  "routematch_pickup_address_id"
    t.integer  "dropoff_address_id"
    t.integer  "routematch_dropoff_address_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.string   "run_id",                           :limit => 36
    t.integer  "trip_import_id"
    t.integer  "routematch_trip_id"
    t.string   "result_code",                      :limit => 5
    t.string   "provider_code",                    :limit => 10
    t.integer  "allocation_id"
    t.decimal  "customer_pay",                                   :precision => 10, :scale => 2
    t.integer  "home_address_id"
    t.integer  "duration"
    t.decimal  "mileage",                                        :precision => 8,  :scale => 1
    t.decimal  "apportioned_duration",                           :precision => 7,  :scale => 2
    t.decimal  "apportioned_mileage",                            :precision => 9,  :scale => 2
    t.decimal  "apportioned_fare",                               :precision => 10, :scale => 2
    t.integer  "updated_by"
    t.datetime "imported_at"
  end

  add_index "trips", ["allocation_id", "date"], :name => "trips_allocation_date_idx"
  add_index "trips", ["base_id"], :name => "trips_base_id_idx"
  add_index "trips", ["date"], :name => "trips_date_idx"
  add_index "trips", ["run_id"], :name => "trips_run_id_idx"

  create_table "users", :force => true do |t|
    t.string   "name",                             :null => false
    t.string   "email",                            :null => false
    t.text     "crypted_password",                 :null => false
    t.boolean  "no_login"
    t.integer  "created_by"
    t.string   "persistence_token",                :null => false
    t.integer  "login_count",       :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level",             :default => 0
  end

  add_foreign_key "runs", ["trip_import_id"], "trip_imports", ["id"], :name => "runs_trip_import_id_fkey"

end
