class Trip < ActiveRecord::Base
  require 'bigdecimal'
  extend ActiveSupport::Memoizable

  class << self
    def date_range(start_date, after_end_date)
      start_date = start_date.to_date
      after_end_date = after_end_date.to_date
      where("trips.date >= ? AND trips.date < ?",start_date,after_end_date)
    end
  end

  stampable :updater_attribute  => :updated_by,
            :creator_attribute  => :updated_by
  point_in_time
  belongs_to :pickup_address, :class_name => "Address", :foreign_key => "pickup_address_id"
  belongs_to :dropoff_address, :class_name => "Address", :foreign_key => "dropoff_address_id"
  belongs_to :home_address, :class_name => "Address", :foreign_key => "home_address_id"
  belongs_to :allocation
  belongs_to :run, :primary_key=>"base_id"
  belongs_to :customer
  belongs_to :trip_import

  after_validation :set_duration_and_mileage
  after_save :apportion_shared_rides
  after_create :apportion_new_run_based_trips

  attr_protected :apportioned_fare, :apportioned_mileage, :apportioned_duration
  attr_protected :mileage, :duration

  attr_accessor :bulk_import, :secondary_update, :do_not_version

  scope :completed, where(:result_code => 'COMP')
  scope :data_entry_complete, where(:complete => true)
  scope :shared, where('trips.routematch_share_id IS NOT NULL')
  scope :spd, joins(:allocation=>:project).where(:projects => {:funding_source => 'SPD'})

  RESULT_CODES = {'Completed' => 'COMP','Turned Down' => 'TD','No Show' => 'NS','Unmet Need' => 'UNMET','Cancelled' => 'CANC'}

  def created_by
    return first_version.updated_by
  end

  def completed?
    result_code == 'COMP'
  end

  def shared?
    routematch_share_id.present?
  end
  
  def updated_by_user
    return (self.updated_by.nil? ? User.find(:first) : User.find(self.updated_by)) #right now, imports run through the command line will have no user info
  end

  def customers_served
    guest_count + attendant_count + 1
  end
  
  def chronological_versions
    return self.versions.sort{|t1,t2|t1.updated_at <=> t2.updated_at}.reverse
  end

  def wheelchair?
    if mobility == "Ambulatory" 
      false
    elsif mobility.nil?
      nil
    else
      true
    end
  end 

  def spd_mileage
    if self.estimated_trip_distance_in_miles < 5
      return 0
    elsif self.estimated_trip_distance_in_miles < 25
      return self.estimated_trip_distance_in_miles - 5
    else
      return 20
    end
  end

  memoize :customers_served

  def create_revision_with_known_attributes_without_callbacks(attrs)
    old_version = versions.build self.attributes.merge( attrs )

    old_version.valid_end = now_rounded
    old_version.should_run_callbacks = false
    old_version.save!(:validate=>false)
  end

private

  def create_new_version?
    !do_not_version?
  end
  
  def do_not_version?
    do_not_version == true || do_not_version.to_i == 1 || !complete || !complete_was
  end

  def set_duration_and_mileage
    unless secondary_update 
      if completed? && (allocation.run_collection_method == 'trips')
        self.duration = ((end_at - start_at) / 60 ).to_i unless end_at.nil? || start_at.nil?
        self.mileage = odometer_end - odometer_start unless odometer_end.nil? || odometer_start.nil?
        if routematch_share_id.blank?
          self.apportioned_fare = fare unless fare.nil?
          self.apportioned_duration = duration unless duration.nil?
          self.apportioned_mileage = mileage unless mileage.nil?
        end
      end
    end
  end

  def apportion_shared_rides
    unless secondary_update || bulk_import
      return if should_run_callbacks == false

      # currently shared, update new routematch_share rides
      reapportion_trips_for_routematch_share_id( routematch_share_id ) if shared? 

      if routematch_share_id_changed?
        # previously shared, update old routematch_share rides
        reapportion_trips_for_routematch_share_id( routematch_share_id_change.first ) if routematch_share_id_change.first.present?
      end
    end
    return true
  end
  
  def reapportion_trips_for_routematch_share_id(rms_id)
    r = Trip.current_versions.completed.where(:routematch_share_id => rms_id, :date => date).order(:end_at,:created_at)
    # All these aggregates are run separately.  
    # could be optimized into one query with a custom SELECT statement.
    trip_count   = r.count
    ride_duration = ((r.maximum(:end_at) - r.minimum(:start_at)) / 60).to_i
    ride_mileage  = r.maximum(:odometer_end) - r.minimum(:odometer_start)
    ride_cost     = r.sum(:fare)
    all_est_miles = r.sum(:estimated_trip_distance_in_miles)

    # Keep a tally of apportionments made so any remainder can be applied to the last trip.
    ride_duration_remaining = ride_duration
    ride_mileage_remaining = ride_mileage
    ride_cost_remaining = ride_cost
        
    trip_position = 0

    for t in r
      trip_position += 1
      # Avoid infinite recursion
      t.secondary_update = true

      this_ratio = t.estimated_trip_distance_in_miles / all_est_miles

      this_trip_duration = ((ride_duration.to_f * this_ratio) * 100).floor.to_f / 100
      ride_duration_remaining = (ride_duration_remaining - this_trip_duration).round(2)
      t.apportioned_duration = this_trip_duration + ( trip_position == trip_count ? ride_duration_remaining : 0 )

      this_trip_mileage = ((ride_mileage * this_ratio) * 100).floor.to_f / 100 
      ride_mileage_remaining = (ride_mileage_remaining - this_trip_mileage).round(2)
      t.apportioned_mileage = this_trip_mileage + ( trip_position == trip_count ? ride_mileage_remaining : 0 )

      this_trip_cost = ((ride_cost * this_ratio) * 100).floor.to_f / 100
      ride_cost_remaining = (ride_cost_remaining - this_trip_cost).round(2)
      t.apportioned_fare = this_trip_cost + ( trip_position == trip_count ? ride_cost_remaining : 0 )
      t.do_not_version = true
      t.save!
    end
  end

  def apportion_new_run_based_trips
    if !should_run_callbacks
      return true
    end
    unless secondary_update || bulk_import
      self.run.save!
    end
  end
end
