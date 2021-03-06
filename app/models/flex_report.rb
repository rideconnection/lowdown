class FlexReport < ActiveRecord::Base
  belongs_to :report_category

  validates :name, presence: true, uniqueness: true
  validates_date :start_date, :end_date, allow_blank: true

  attr_accessor :is_new
  attr_accessor :allocation_objects
  attr_accessor :report_rows
  attr_reader   :results

  TimePeriods = %w{semimonth month quarter year}

  # Default group-by options would go here. Since every report is so different,
  # the defaults have been removed
  GroupBys = []

  GroupMappings = {
    "trip_collection_method_name"   => "Trip Collection Method",
    "county"                        => "County",
    "funding_source"                => "Funding Source",
    "funding_subsource"             => "Funding Subsource",
    "funding_source_and_subsource"  => "Funding Source and Subsource",
    "override_name"                 => "Override Name",
    "allocation_name"               => "Allocation Name",
    "program_name"                  => "Program Name",
    "service_type_name"             => "Service Type Name",
    "project_name"                  => "F.E. Project Name",
    "project_number"                => "F.E. Project Number",
    "project_number_and_name"       => "F.E. Project Number and Name",
    "provider_name"                 => "Provider Name",
    "provider_type"                 => "Provider Type",
    "reporting_agency_name"         => "Reporting Agency Name",
    "reporting_agency_type"         => "Reporting Agency Type",
    "trimet_program_name"           => "TriMet Program Name",
    "trimet_program_identifier"     => "TriMet Program Identifier",
    "trimet_provider_name"          => "TriMet Provider Name",
    "trimet_provider_identifier"    => "TriMet Provider Identifier",
    "trip_purpose"                  => "Trip Purpose",
    "semimonth"                     => "Semi-month",
    "month"                         => "Month",
    "quarter"                       => "Quarter",
    "year"                          => "Year"
  }

  # Apply the specified block to the leaves of a nested hash (leaves
  # are defined as elements {depth} levels deep, so that hashes
  # can be leaves)
  def self.apply_to_leaves!(group, depth, &block)
    if depth == 0
      return block.call group
    else
      group.each do |k, v|
        group[k] = FlexReport.apply_to_leaves! v, depth - 1, &block
      end
      return group
    end
  end

  def end_month
    Date.new(end_date.year, end_date.month, 1) if end_date.present?
  end

  def end_month=(value)
    if value.is_a?(Hash)
      self.end_date = Date.new(value[1],value[2],1) + 1.month - 1.day
    else
      self.end_date = Date.new(value.year,value.month,1) + 1.month - 1.day
    end
  end

  def after_end_date
    end_date + 1.day if end_date.present?
  end

  def trip_collection_methods
    if trip_collection_method_list.blank?
      [""]
    else
      trip_collection_method_list.split("|")
    end
  end

  def trip_collection_methods=(list)
    if list.blank?
      self.trip_collection_method_list = nil
    else
      self.trip_collection_method_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def projects
    project_list.blank? ? [] : Project.where(id: project_list.split(",").map(&:to_i))
  end

  def project_ids
    project_list.blank? ? [""] : project_list.split(",").map(&:to_i)
  end

  def projects=(list)
    if list.blank?
      self.project_list = nil
    else
      self.project_list = list.sort.map(&:to_s).join(",")
    end
  end

  def service_types
    service_type_list.blank? ? [] : ServiceType.where(id: service_type_list.split(",").map(&:to_i))
  end

  def service_type_ids
    service_type_list.blank? ? [""] : service_type_list.split(",").map(&:to_i)
  end

  def service_types=(list)
    if list.blank?
      self.service_type_list = nil
    else
      self.service_type_list = list.sort.map(&:to_s).join(",")
    end
  end

  def funding_sources
    funding_source_list.blank? ? [] : FundingSource.where(id: funding_source_list.split(",").map(&:to_i))
  end

  def funding_source_ids
    funding_source_list.blank? ? [""] : funding_source_list.split(",").map(&:to_i)
  end

  def funding_sources=(list)
    if list.blank?
      self.funding_source_list = nil
    else
      self.funding_source_list = list.sort.map(&:to_s).join(",")
    end
  end

  def programs
    program_list.blank? ? [] : Program.where(id: program_list.split(",").map(&:to_i))
  end

  def program_ids
    program_list.blank? ? [""] : program_list.split(",").map(&:to_i)
  end

  def programs=(list)
    if list.blank?
      self.program_list = nil
    else
      self.program_list = list.sort.map(&:to_s).join(",")
    end
  end

  def county_names
    if county_name_list.blank?
      [""]
    else
      county_name_list.split("|")
    end
  end

  def county_names=(list)
    if list.blank?
      self.county_name_list = nil
    else
      self.county_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def reporting_agency_type_names
    if reporting_agency_type_name_list.blank?
      [""]
    else
      reporting_agency_type_name_list.split("|")
    end
  end

  def reporting_agency_type_names=(list)
    if list.blank?
      self.reporting_agency_type_name_list = nil
    else
      self.reporting_agency_type_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def reporting_agencies
    reporting_agency_list.blank? ? [] : Provider.where(id: reporting_agency_list.split(",").map(&:to_i))
  end

  def reporting_agency_ids
    reporting_agency_list.blank? ? [""] : reporting_agency_list.split(",").map(&:to_i)
  end

  def reporting_agencies=(list)
    if list.blank?
      self.reporting_agency_list = nil
    else
      self.reporting_agency_list = list.sort.map(&:to_s).join(",")
    end
  end

  def provider_type_names
    if provider_type_name_list.blank?
      [""]
    else
      provider_type_name_list.split("|")
    end
  end

  def provider_type_names=(list)
    if list.blank?
      self.provider_type_name_list = nil
    else
      self.provider_type_name_list = list.reject {|x| x == ""}.sort.map(&:to_s).join("|")
    end
  end

  def providers
    provider_list.blank? ? [] : Provider.where(id: provider_list.split(",").map(&:to_i))
  end

  def provider_ids
    provider_list.blank? ? [""] : provider_list.split(",").map(&:to_i)
  end

  def providers=(list)
    if list.blank?
      self.provider_list = nil
    else
      self.provider_list = list.sort.map(&:to_s).join(",")
    end
  end

  def allocations
    allocation_list.blank? ? [] : Allocation.where(id: allocation_list.split(",").map(&:to_i))
  end

  def allocation_ids
    allocation_list.blank? ? [""] : allocation_list.split(",").map(&:to_i)
  end

  def allocations=(list)
    if list.blank?
      self.allocation_list = ''
    else
      self.allocation_list = list.sort.map(&:to_s).join(",")
    end
  end

  def fields
    if field_list
      return field_list.split(",")
    else
      return []
    end
  end

  def fields=(list)
    return self.field_list = '' if list.to_s.empty?

    list = list.keys if list.respond_to?(:keys)
    self.field_list = list.sort.map(&:to_s).join(",")
  end

  def uses_vehicle_maint_field?
    fields.include?('vehicle_maint') ||
      (fields.include?('total') && fields & %w{funds agency_other vehicle_maint administrative operations donations}  == [])
  end

  def uses_administrative_or_operations_fields?
    fields.include?('administrative') || fields.include?('operations') ||
      (fields.include?('total') && (fields & %w{funds agency_other vehicle_maint administrative operations donations})  == [])
  end

  def group_fields
    group_by.split(",")
  end

  def diff(other)
    unequal_rows = {}
    report_rows.keys.each do |row_allocation|
      other_row_allocation = other.report_rows.keys.detect{|a| row_allocation == a }
      this_diff = report_rows[row_allocation].diff(other.report_rows[other_row_allocation])
      unequal_rows[row_allocation] = this_diff if this_diff.present?
    end
    unequal_rows
  end

  # Based on the flex report definition, collect all the actual allocations for which data needs to be gathered.
  # If there are time periods, then take each allocation and expand it into the requested time periods.
  # If there is grouping by trip purpose, explode allocations by trip purposes.
  def collect_allocation_objects!(allocation_instance = Allocation)
    where_strings = []
    where_params = []

    where_strings << "do_not_show_on_flex_reports = false"

    where_strings << "(inactivated_on IS NULL OR inactivated_on > ?) AND activated_on < ?"
    where_params.concat [start_date, after_end_date]

    if funding_source_list.present?
      where_strings << "project_id IN (SELECT id FROM projects WHERE funding_source_id IN (?))"
      where_params << funding_source_ids
    end
    if project_list.present?
      where_strings << "project_id IN (?)"
      where_params << project_ids
    end
    if reporting_agency_list.present?
      where_strings << "reporting_agency_id IN (?)"
      where_params << reporting_agency_ids
    end
    if provider_list.present?
      where_strings << "provider_id IN (?)"
      where_params << provider_ids
    end
    if program_list.present?
      where_strings << "program_id IN (?)"
      where_params << program_ids
    end
    if service_type_list.present?
      where_strings << "service_type_id IN (?)"
      where_params << service_type_ids
    end
    if county_name_list.present?
      where_strings << "county IN (?)"
      where_params << county_names
    end
    if trip_collection_method_list.present?
      where_strings << "trip_collection_method IN (?)"
      where_params << trip_collection_methods
    end
    if reporting_agency_type_name_list.present?
      where_strings << "reporting_agency_id IN (SELECT id FROM providers WHERE provider_type IN (?))"
      where_params << reporting_agency_type_names
    end
    if provider_type_name_list.present?
      where_strings << "provider_id IN (SELECT id FROM providers WHERE provider_type IN (?))"
      where_params << provider_type_names
    end

    if where_strings.present?
      where_string = where_strings.join(" AND ")
      if allocations.present?
        where_string = "(#{where_string}) OR allocations.id IN (?)"
        where_params << allocation_ids
      end
    elsif allocations.present?
        where_string = "allocations.id IN (?)"
        where_params << allocation_ids
    end

    # There are allocations that are dedicated to only tracking certain data points:
    # vehicle maintenance or admin/ops costs. If the user doesn't request the fields that would
    # involve the related allocations, then filter out those allocations
    allocation_instance = allocation_instance.exclude_vehicle_maint_data_only if !uses_vehicle_maint_field?
    allocation_instance = allocation_instance.exclude_admin_ops_data_only if !uses_administrative_or_operations_fields?

    results = allocation_instance.where(where_string, *where_params)

    # Convert the final allocation list to report row allocations, which can track date groupings and trip purposes
    report_row_allocations = []
    results.each do |a|
      report_row_allocations << ReportRowAllocation.new(
        report_start_date:      start_date,
        report_after_end_date:  after_end_date,
        allocation:             a,
        trip_purpose:           'N/A'
      )
    end

    # TimePeriods are sorted shortest to longest
    # Only apply the shortest time period if there are multiple time period grouping levels
    period_group = (TimePeriods & group_fields).first
    if period_group.present?
      report_row_allocations = ReportRowAllocation.apply_periods(report_row_allocations, period_group)
    end

    if group_fields.member? "trip_purpose"
      report_row_allocations = ReportRowAllocation.apply_trip_purposes(report_row_allocations)
    end

    @allocation_objects = report_row_allocations
  end

  # Gather the data for the selected allocations
  def collect_report_data!
    options = {}
    options[:pending]      = pending
    options[:trip_purpose] = group_fields.include?("trip_purpose")

    # Create a report_row object for each report_row_allocation object
    @report_rows = {}
    @allocation_objects.each do |ao|
      row = ReportRow.new fields, ao
      @report_rows[ao] = row
    end

    if elderly_and_disabled_only
      # For the special case of filtering down to just E&D trips throughout the data set,
      # set things up to collect data twice, in two different ways.
      # First filter down to E&D only allocations and collect all their data,
      # and then filter down to allocations that include non-E&D customers and
      # within those allocations filter down to trips that were specifically
      # marked as being for E&D customers.
      ed_handling_values = [
        {allocations: :ed,     filter_trips_for_ed_only: false},
        {allocations: :non_ed, filter_trips_for_ed_only: true }
      ]
    else
      ed_handling_values = [
        {allocations: :all,    filter_trips_for_ed_only: false}
      ]
    end

    # Collect all the unique date ranges for this report
    date_ranges = []
    @allocation_objects.each do |ao|
      this_date_range = {start_date: ao.collection_start_date, after_end_date: ao.collection_after_end_date}
      date_ranges << this_date_range unless date_ranges.include? this_date_range
    end

    # Collect the actual data
    ed_handling_values.each do |ed_handling|
      options[:elderly_and_disabled_only] = ed_handling[:filter_trips_for_ed_only]
      if ed_handling[:allocations] == :ed
        allocation_group = @allocation_objects.select{|ao| ao.eligibility == 'Elderly & Disabled'}
      elsif ed_handling[:allocations] == :non_ed
        allocation_group = @allocation_objects.select{|ao| ao.eligibility != 'Elderly & Disabled'}
      else
        allocation_group = @allocation_objects
      end
      collect_report_results_by_data_type allocation_group,
                                          date_ranges,
                                          options
    end

    # Now that all the data is in, perform final calculations for calculated row fields
    @report_rows.each do |key, row|
      row.calculate_summable_calculated_fields!
    end
  end

  # Group data into nested sets.  Merge report row objects at the finest group level.
  def group_report_rows!
    grouped_rows = Allocation.group(group_fields, @report_rows.keys)
    FlexReport.apply_to_leaves! grouped_rows, group_fields.size do | allocationset |
      row = ReportRow.new fields, allocationset[0]
      allocationset.each do |allocation|
        row.include_row(@report_rows[allocation])
      end
      row
    end
    @results = grouped_rows
  end

  # Convenience function for running a flex report from a saved definition.
  def populate_results!(allocation_instance = Allocation)
    collect_allocation_objects!(allocation_instance)
    collect_report_data!
    group_report_rows!
  end

  def collect_report_results_by_data_type(allocation_group, these_date_ranges, options)
    # Collect trip data
    if (fields & ReportRow.trip_fields.map{|f| f.to_s }).present?
      these_allocations = allocation_group.select{|ao| ao.trip_collection_method == 'trips'}
      if these_allocations.present?
        collect_all_trips_by_trip(these_allocations, these_date_ranges, options)
      end
      these_allocations = allocation_group.select{|ao| ao.trip_collection_method == 'summary'}
      if these_allocations.present?
        collect_all_trips_by_summary(these_allocations, these_date_ranges, options)
      end
    end

    # Collect run data
    if (fields & ReportRow.run_fields.map{|f| f.to_s }).present?
      these_allocations = allocation_group.select{|ao| ao.run_collection_method == 'trips'}
      if these_allocations.present?
        collect_all_runs_by_trip(these_allocations, these_date_ranges, options)
      end
      these_allocations = allocation_group.select{|ao| ao.run_collection_method == 'runs'}
      if these_allocations.present?
        collect_all_runs_by_run(these_allocations, these_date_ranges, options)
      end
      these_allocations = allocation_group.select{|ao| ao.run_collection_method == 'summary'}
      if these_allocations.present?
        collect_all_runs_by_summary(these_allocations, these_date_ranges, options)
      end
    end

    # Collect cost data
    if (fields & ReportRow.cost_fields.map{|f| f.to_s }).present?
      these_allocations = allocation_group.select{|ao| ao.cost_collection_method == 'summary'}
      if these_allocations.present?
        collect_all_costs_by_summary(these_allocations, these_date_ranges, options)
      end
      collect_all_costs_by_trip(allocation_group, these_date_ranges, options)
    end

    # Collect operations data
    if (fields & ReportRow.operations_fields.map{|f| f.to_s }).present? ||
        uses_vehicle_maint_field? || uses_administrative_or_operations_fields?
      collect_all_operation_data_by_summary(allocation_group, these_date_ranges, options)
    end

    if elderly_and_disabled_only
      @report_rows.values.each {|rr| rr.calculate_total_elderly_and_disabled_cost }
    end
  end

  def apply_results_to_report_rows(result_rows)
    result_rows.each do |results|
      if results.attributes.has_key?("purpose_type")
        trip_purpose = TRIP_PURPOSE_TO_SUMMARY_PURPOSE[results.attributes["purpose_type"]]
        trip_purpose = "Unspecified" if trip_purpose.nil?
      elsif results.attributes.has_key?("purpose")
        trip_purpose = results.attributes["purpose"]
      else
        trip_purpose = 'N/A'
      end

      this_allocation = @allocation_objects.detect do |ao|
        (
          ao.id                        == results['allocation_id']  &&
          ao.collection_start_date     == results['start_date']     &&
          ao.collection_after_end_date == results['after_end_date'] &&
          ao.trip_purpose              == trip_purpose
        )
      end
      @report_rows[this_allocation].apply_results(results.attributes.reject{|k,v| k.in? %w(allocation_id start_date after_end_date purpose purpose_type) })
    end
  end

  def collect_all_trips_by_trip(allocations, these_date_ranges, options = {})
    select = "
      SUM(
        CASE WHEN in_trimet_district=true AND result_code = 'COMP'
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS in_district_trips,
      SUM(
        CASE WHEN in_trimet_district=false AND result_code = 'COMP'
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS out_of_district_trips,
      SUM(
        CASE WHEN result_code = 'COMP'
        THEN 1
        ELSE 0
        END) AS customer_trips,
      SUM(
        CASE WHEN result_code = 'COMP'
        THEN guest_count + attendant_count
        ELSE 0
        END) AS guest_and_attendant_trips,
      SUM(
        CASE WHEN result_code='TD'
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS turn_downs,
      SUM(
        CASE WHEN result_code='NS'
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS no_shows,
      SUM(
        CASE WHEN result_code='CANC'
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS cancellations,
      SUM(
        CASE WHEN result_code='UNMET'
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS unmet_need,
      SUM(
        CASE WHEN result_code NOT IN ('COMP','TD','NS','CANC','UNMET') OR result_code IS NULL
        THEN 1 + guest_count + attendant_count
        ELSE 0
        END) AS other_results"
    select += ", purpose_type" if options[:trip_purpose]
    results = common_filters(Trip, select, allocations, these_date_ranges, options)
    results = results.group(:purpose_type) if options[:trip_purpose]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]
    apply_results_to_report_rows(results)

    if fields.include?('undup_riders')
      # Collect unduplicated customer counts. If the date range doesn't start at the beginning
      # of the fiscal year, exclude customers from prior in the fiscal year
      select = "COUNT(DISTINCT customer_id) AS undup_riders"
      results = common_filters(Trip, select, allocations, these_date_ranges, options)
      results = results.completed.exclude_customers_earlier_in_fiscal_year(options)
      results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]
      apply_results_to_report_rows(results)
    end

    if (fields & %w{volunteer_driver_trips paid_driver_trips}).present?
      select = "
        SUM(
          CASE WHEN result_code = 'COMP' AND run_id IN (SELECT id FROM runs WHERE volunteer_run = true)
          THEN 1 + guest_count + attendant_count
          ELSE 0
          END) AS trips_marked_as_volunteer"
      select += ", purpose_type" if options[:trip_purpose]
      results = common_filters(Trip, select, allocations, these_date_ranges, options)
      results = results.group(:purpose_type) if options[:trip_purpose]
      results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]
      apply_results_to_report_rows(results)
    end

    # Collect the total_general_public_trips only if we're dealing with a service that's
    # not strictly for elderly and disabled customers.
    # This will be used to create a ratio of E&D to total trips
    # so that we can calculate costs for the TriMet E&D report.
    if options[:elderly_and_disabled_only]
      select = "
        SUM(
          CASE WHEN result_code = 'COMP'
          THEN 1 + guest_count + attendant_count
          ELSE 0
          END) AS total_general_public_trips"
      results = common_filters(Trip, select, allocations, these_date_ranges, options)
      apply_results_to_report_rows(results)
    end
  end

  def collect_all_trips_by_summary(allocations, these_date_ranges, options = {})
    unless options[:elderly_and_disabled_only]
      select = "
                SUM(in_district_trips) AS in_district_trips,
                SUM(out_of_district_trips) AS out_of_district_trips,
                SUM(in_district_trips + out_of_district_trips) AS customer_trips,
                0 AS guest_and_attendant_trips"
      select += ", purpose" if options[:trip_purpose]
      results = common_filters(Summary, select, allocations, these_date_ranges, options)
      results = results.joins(:summary_rows)
      results = results.group(:purpose) if options[:trip_purpose]
      apply_results_to_report_rows(results)

      if (fields & ['turn_downs', 'undup_riders']).present?
        select = "SUM(turn_downs) AS turn_downs,
                  SUM(unduplicated_riders) AS undup_riders"
        results = common_filters(Summary, select, allocations, these_date_ranges, options)
        apply_results_to_report_rows(results)
      end
    end

    # Collect the total_general_public_trips only if we're dealing with a service that's
    # not strictly for elderly and disabled customers.  This will be used in the E&D audit export
    if options[:elderly_and_disabled_only]
      select = "SUM(in_district_trips) + SUM(out_of_district_trips) AS total_general_public_trips"
      results = common_filters(Summary, select, allocations, these_date_ranges, options)
      results = results.joins(:summary_rows)
      apply_results_to_report_rows(results)
    end
  end

  def collect_all_runs_by_trip(allocations, these_date_ranges, options = {})
    select = "SUM(apportioned_mileage) AS mileage,
              SUM(
                CASE WHEN COALESCE(volunteer_trip,false)=false
                THEN apportioned_duration
                ELSE 0
                END)/3600.0 AS driver_paid_hours,
              SUM(
                CASE WHEN volunteer_trip=true
                THEN apportioned_duration
                ELSE 0
                END)/3600.0 AS driver_volunteer_hours,
              0 AS escort_volunteer_hours"
    select += ", purpose_type" if options[:trip_purpose]
    results = common_filters(Trip, select, allocations, these_date_ranges, options)
    results = results.group(:purpose_type) if options[:trip_purpose]
    results = results.completed
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]
    apply_results_to_report_rows(results)
  end

  def collect_all_runs_by_run(allocations, these_date_ranges, options = {})
    select = "SUM(apportioned_mileage) AS mileage,
              SUM(
                CASE WHEN COALESCE(volunteer_trip,false)=false
                THEN apportioned_duration
                ELSE 0
                END)/3600.0 AS driver_paid_hours,
              SUM(
                CASE WHEN volunteer_trip=true
                THEN apportioned_duration
                ELSE 0
                END)/3600.0 AS driver_volunteer_hours,
              SUM(COALESCE((
                SELECT escort_count
                FROM runs
                WHERE id = trips.run_id
                ),0) * apportioned_duration)/3600.0 AS escort_volunteer_hours"
    results = common_filters(Trip, select, allocations, these_date_ranges, options)
    results = results.completed
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]
    apply_results_to_report_rows(results)
  end

  def collect_all_runs_by_summary(allocations, these_date_ranges, options = {})
    unless options[:elderly_and_disabled_only]
      select = "SUM(total_miles) AS mileage,
                SUM(driver_hours_paid) AS driver_paid_hours,
                SUM(driver_hours_volunteer) AS driver_volunteer_hours,
                SUM(escort_hours_volunteer) AS escort_volunteer_hours"
      results = common_filters(Summary, select, allocations, these_date_ranges, options)
      apply_results_to_report_rows(results)
    end
  end

  def collect_all_costs_by_trip(allocations, these_date_ranges, options = {})
    select = "SUM(apportioned_fare) AS funds,
              0 AS agency_other,
              0 AS donations"
    select += ", purpose_type" if options[:trip_purpose]
    results = common_filters(Trip, select, allocations, these_date_ranges, options)
    results = results.group(:purpose_type) if options[:trip_purpose]
    results = results.elderly_and_disabled_only if options[:elderly_and_disabled_only]
    apply_results_to_report_rows(results)

    # Collect the total_general_public_cost only if we're dealing with a service that's
    # not strictly for elderly and disabled customers. This is used for audit purposes.
    if options[:elderly_and_disabled_only]
      select = "SUM(apportioned_fare) AS total_general_public_cost"
      results = common_filters(Trip, select, allocations, these_date_ranges, options)
      apply_results_to_report_rows(results)
    end
  end

  def collect_all_costs_by_summary(allocations, these_date_ranges, options = {})
    select = "SUM(funds) AS funds,
              SUM(agency_other) AS agency_other,
              SUM(donations) AS donations"
    results = common_filters(Summary, select, allocations, these_date_ranges, options)
    apply_results_to_report_rows(results)
  end

  def collect_all_operation_data_by_summary(allocations, these_date_ranges, options = {})
    unless options[:elderly_and_disabled_only]
      select = "SUM(operations) AS operations,
                SUM(administrative) AS administrative,
                SUM(vehicle_maint) AS vehicle_maint,
                SUM(administrative_hours_volunteer) AS admin_volunteer_hours"
      results = common_filters(Summary, select, allocations, these_date_ranges, options)
      apply_results_to_report_rows(results)
    end
  end

  def common_filters(model, select, allocations, these_date_ranges, options)
    select  = "allocation_id, ranges.start_date, ranges.after_end_date, #{select}"
    results = model.select(select).group("allocation_id, ranges.start_date, ranges.after_end_date")
    results = results.where(allocation_id: allocations.map{|a| a.id}.uniq)
    results = results.current_versions.for_date_ranges(these_date_ranges)
    results = results.data_entry_complete unless options[:pending]
    results
  end
end
