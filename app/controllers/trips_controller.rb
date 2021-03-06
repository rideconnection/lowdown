require 'csv'

class TripQuery
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :all_dates, :start_date, :end_date, :after_end_date, :provider_id, :reporting_agency_id, 
      :allocation_id_list, :allocation_id, :allocation_ids, :customer_first_name, :customer_last_name, 
      :dest_allocation_id, :commit, :trip_import_id, :adjustment_notes, :display_search_form, :run_id, 
      :share_id, :valid_start, :result_code, :original_override, :program_id,
      :trip_purpose, :data_entry_complete

  def initialize(params, commit = nil)
    params ||= {}
    @commit              = commit
    @trip_import_id      = params[:trip_import_id].present? ? params[:trip_import_id].to_i : nil
    @valid_start         = params[:valid_start].present? ? Time.parse(params[:valid_start]) : nil
    @run_id              = params[:run_id].present? ? params[:run_id].to_i : nil
    @share_id            = params[:share_id].present? ? params[:share_id].to_i : nil
    @display_search_form = !(@trip_import_id || @run_id || @share_id || @valid_start)
    if @display_search_form
      @all_dates         = (params[:all_dates] == "1" || params[:all_dates] == true)
    else
      @all_dates         = true
    end

    @start_date          = Date.parse(params["start_date"]) if params["start_date"].present?
    @end_date            = Date.parse(params["end_date"])   if params["end_date"].present?
    if @start_date.blank? || @end_date.blank?
      if params['date_range'] == "semimonthly" 
        if Date.today.day > 15
          @start_date = Date.today - Date.today.day + 1.day
          @end_date   = @start_date + 14.days
        else
          @end_date   = Date.today - Date.today.day
          @start_date = @end_date - @end_date.day + 16.days
        end
      else
        @start_date   = Date.today - 1.month - Date.today.day + 1.day
        @end_date     = @start_date + 1.month - 1.day
      end
    end
    @after_end_date      = @end_date + 1.day
    @provider_id         = params[:provider_id].to_i         if params[:provider_id].present? 
    @program_id          = params[:program_id].to_i          if params[:program_id].present? 
    @reporting_agency_id = params[:reporting_agency_id].to_i if params[:reporting_agency_id].present? 
    @dest_allocation_id  = params[:dest_allocation_id].to_i  if params[:dest_allocation_id].present? 
    @allocation_id       = params[:allocation_id].to_i       if params[:allocation_id].present? 
    @allocation_id_list  = params[:allocation_id_list]       if params[:allocation_id_list].present?
    @result_code         = params[:result_code]
    @customer_first_name = params[:customer_first_name]
    @customer_last_name  = params[:customer_last_name]
    @original_override   = params[:original_override]
    @trip_purpose        = params[:trip_purpose]
    @data_entry_complete = (params[:data_entry_complete] == 'Yes' ? true : false) if params[:data_entry_complete].in?(%w{Yes No})
    @allocation_ids      = @allocation_id_list.split.map{|al| al.to_i} if @allocation_id_list.present?
  end

  def persisted?
    false
  end

  def apply_conditions(trips)
    trips = trips.for_date_range(start_date,after_end_date)         if !all_dates
    trips = trips.for_provider(provider_id)                         if provider_id.present?
    trips = trips.for_program_id(program_id)                        if program_id.present?
    trips = trips.for_valid_start(valid_start)                      if valid_start.present?
    trips = trips.for_reporting_agency(reporting_agency_id)         if reporting_agency_id.present?
    trips = trips.for_allocation_id(allocation_id)                  if allocation_id.present?
    trips = trips.for_allocation_id(allocation_ids)                 if allocation_ids.present?
    trips = trips.for_import(trip_import_id)                        if trip_import_id.present?
    trips = trips.for_run(run_id)                                   if run_id.present?
    trips = trips.for_result_code(result_code)                      if result_code.present?
    trips = trips.for_share(share_id)                               if share_id.present?
    trips = trips.for_customer_first_name_like(customer_first_name) if customer_first_name.present?
    trips = trips.for_customer_last_name_like(customer_last_name)   if customer_last_name.present?
    trips = trips.for_original_override_like(original_override)     if original_override.present?
    trips = trips.for_trip_purpose(trip_purpose)                    if trip_purpose.present?
    trips = trips.where(complete: data_entry_complete)              unless data_entry_complete.nil?
    trips
  end
  
  def update_allocation?
    @commit.try(:downcase) == "transfer trips" && 
      @dest_allocation_id.present? && 
      @dest_allocation_id != @allocation_id &&
      Allocation.find(@allocation_id).try(:provider) == Allocation.find(@dest_allocation_id).try(:provider)
  end

  def format
    return if @commit.blank?
    if @commit == "Export BPA Invoice Data"
      "bpa"
    elsif @commit == "Export All Data Fields"
      "general"
    elsif @commit == "Export For Trip Analysis"
      "analysis"
    end
  end
end

class TripImportQuery
  attr_accessor :provider_id

  def initialize(params)
    params ||= {}
    @provider_id = params[:provider_id].to_i if params[:provider_id].present? 
  end

  def apply_conditions(trip_imports)
    trip_imports = trip_imports.for_provider_id(provider_id) if provider_id.present?
    trip_imports
  end
end

class TripsController < ApplicationController

  before_filter :require_admin_user, except: [:index, :list, :show_import, :adjustments, :show]

  def index
    @query = TripQuery.new params[:q], params[:commit]
    prep_search
    @trips = @query.apply_conditions(Trip).
        current_versions.
        index_includes.
        order(:date,:trip_import_id)

    if @query.format == 'general'
      @filename = 'trip_list.csv'
      render 'index.csv'
    elsif @query.format == 'bpa'
      @trips = @trips.completed
      @filename = 'bpa_index.csv'
      render 'bpa_index.csv'
    elsif @query.format == 'analysis'
      render 'analysis_index.csv'
    else
      @trip_count = @query.apply_conditions(Trip).
          current_versions.
          trip_count.
          where(result_code: 'COMP').
          first['trip_count']
      @trips = @trips.paginate page: params[:page], per_page: 30
    end
  end
  
  def show
    @trip = Trip.find(params[:id])
    prep_edit
  end
  
  def update
    @trip = Trip.find(params[:id]).current_version
    @trip.attributes = safe_params
    if has_real_changes? @trip
      if @trip.save  
        redirect_to(@trip)
      else
        prep_edit
        render :show
      end
    else
      redirect_to(@trip)
    end
  end

  def show_update_allocation
    @query       = TripQuery.new params[:q], params[:commit]
    @providers   = Provider.order(:name).with_trip_data
    render :update_allocation
  end

  def update_allocation
    @query       = TripQuery.new params[:q], params[:commit]
    @providers   = Provider.order(:name).with_trip_data
    
    if @query.update_allocation?
      @completed_trips_count = @query.
          apply_conditions(Trip).
          current_versions.
          select("SUM(guest_count) AS g, SUM(attendant_count) AS a, COUNT(*) AS c").
          completed.
          reorder('').
          first.attributes.values.inject(0) {|sum,x| sum + x.to_i }
      @completed_transfer_count = params[:transfer_count].try(:to_i) || 0
      @transfer_all = (params[:transfer_all] == '1' || params[:transfer_all] == true)
      @adjustment_notes = params[:adjustment_notes]
      if @completed_trips_count > 0 || @transfer_all 
        if @transfer_all
          ratio = 1
        else
          ratio = @completed_transfer_count/@completed_trips_count.to_f
        end
        
        @trips_transferred = {}
        now = Trip.new.now_rounded
        
        Trip.transaction do
          Trip::RESULT_CODES.values.each do |rc|
            if rc == 'COMP' && !@transfer_all
              this_transfer_count = @completed_transfer_count
            else
              this_transfer_count = ((@query.
                  apply_conditions(Trip).
                  current_versions.
                  select("COALESCE(SUM(guest_count),0) AS g, COALESCE(SUM(attendant_count),0) AS a, COUNT(*) AS c").
                  where(result_code: rc).
                  reorder('').
                  first.attributes.values.inject(0) {|sum,x| sum + x.to_i }) * ratio).to_i
            end

            trips_remaining = this_transfer_count
            @trips_transferred[rc] = 0
            # This is the maximum number of trips we'll need, if there are no guest or attendants. 
            # It may be fewer when guests & attendants are counted below
            trips = @query.apply_conditions(Trip).
                current_versions.
                where(result_code: rc).
                limit(this_transfer_count)
            if trips.present?
              for trip in trips
                passengers = (trip.guest_count || 0) + (trip.attendant_count || 0) + 1
                if trips_remaining > 0 && passengers <= trips_remaining
                  trip.allocation_id = @query.dest_allocation_id 
                  trip.version_switchover_time = now
                  trip.adjustment_notes = @adjustment_notes if @adjustment_notes
                  trip.save!
                  trips_remaining -= passengers
                  @trips_transferred[rc] += passengers
                end
              end
            end
          end
        end

        @allocation = Allocation.find @query.dest_allocation_id
      end
    end
    @trip_count = {}
    Trip::RESULT_CODES.values.each do |rc|
      @trip_count[rc] = @query.
          apply_conditions(Trip).
          current_versions.
          select("SUM(guest_count) AS g, SUM(attendant_count) AS a, COUNT(*) AS c").
          where(result_code: rc).
          reorder('').
          first.attributes.values.inject(0) {|sum,x| sum + x.to_i }
    end
  end

  def show_import
    @query        = TripImportQuery.new params[:q]
    @providers    = Provider.with_trip_data.default_order
    @trip_imports = @query.apply_conditions(TripImport).
      order("trip_imports.created_at DESC").paginate(
      page: params[:page], 
      per_page: 30
    )
  end

  def adjustments
    prep_search
    @query = TripQuery.new(params[:q])
    @adjustments = @query.apply_conditions(Trip).grouped_by_adjustment.paginate(
      page: params[:page], 
      per_page: 30, 
      total_entries: @query.apply_conditions(Trip).grouped_revisions.to_a.count
    )
  end

  def import
    if params['file-import'].present?
      processed = TripImport.new(
        file_path: params['file-import'].path,
        file_name: params['file-import'].original_filename,
        notes: params['notes']
      )
      if processed.save
        flash[:notice] = "Import complete - #{processed.record_count} records processed.</div>"
      else
        flash[:notice] = "Import aborted due to the following error(s):<br/>#{processed.problems}"
      end
    end
    redirect_to show_import_trips_path
  end

  private

  def safe_params
    params.require(:trip).permit(
      :customer_type,
      :in_trimet_district,
      :case_manager,
      :case_manager_office,
      :date_enrolled,
      :service_end,
      :approved_rides,
      :odometer_start,
      :odometer_end,
      :fare,
      :purpose_type,
      :guest_count,
      :attendant_count,
      :mobility,
      :bpa_driver_name,
      :result_code,
      :allocation_id,
      :customer_pay,
      :complete,
      :adjustment_notes
    )
  end

  def prep_search
    @providers          = Provider.with_trip_data.default_order
    @programs           = Program.with_trip_data.default_order
    @reporting_agencies = Provider.with_trip_data_as_reporting_agency.default_order
    @result_codes       = Trip::RESULT_CODES.sort
    @trip_purposes      = TRIP_PURPOSE_TO_SUMMARY_PURPOSE.values.uniq.sort
    if @query.try(:allocation_ids).present?
      @allocations        = Allocation.where(id: @query.allocation_ids).order(:name)
    end
  end

  def prep_edit
    @customer = @trip.customer
    @home_address = @trip.home_address
    @pickup_address = @trip.pickup_address
    @dropoff_address = @trip.dropoff_address
    @updated_by_user = @trip.updated_by_user
    @result_codes = Trip::RESULT_CODES
    if @trip.result_code.present? && !@result_codes.has_value?(@trip.result_code)
      @result_codes[@trip.result_code] = (@trip.result_code) 
    end
    @allocations = Allocation.order(:name).active_on(@trip.date)
    if @allocations.detect{|a| a.id == @trip.allocation_id}.nil?
      @allocations.unshift Allocation.find(@trip.allocation_id)
    end
  end
end
