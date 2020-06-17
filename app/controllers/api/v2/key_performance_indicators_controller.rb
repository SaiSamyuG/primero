module Api::V2
  class KeyPerformanceIndicatorsController < ApplicationApiController
    # This is only temporary to avoid double render errors while developing.
    # I looks like this method wouldn't make sense for the audit log to
    # write given that 'write_audit_log' required a record type, id etc.
    # This response doesn't utilize any type of record yet and so cannot
    # provide this information.
    skip_after_action :write_audit_log

    def number_of_cases
      search = Child.search do
        facet :created_at,
          tag: :per_month,
          range: from..to,
          range_interval: '+1MONTH',
          minimum_count: -1

        pivot :owned_by_location,
          range: :per_month

        paginate page: 1, per_page: 0
      end

      @columns = search.facet(:created_at).rows.
        map { |result| result.value.first.iso8601(0) }

      @data = search.pivot(:owned_by_location).rows.
        map do |row|
          # use instance to get this?
          location = Location.
            find_by({ location_code: row.result['value'].upcase }).
            placename

          counts = row.range(:created_at).counts

          { reporting_site: location }.merge(counts)
        end
    end

    def number_of_incidents
      search = Incident.search do
        facet :created_at,
          tag: :per_month,
          range: from..to,
          range_interval: '+1MONTH',
          minimum_count: -1

        pivot :owned_by_location,
          range: :per_month

        paginate page: 1, per_page: 0
      end

      @columns = search.facet(:created_at).rows.
        map { |result| result.value.first.iso8601(0) }

      @data = search.pivot(:owned_by_location).rows.
        map do |row|
          # use instance to get this?
          location = Location.
            find_by({ location_code: row.result['value'].upcase }).
            placename

          counts = row.range(:created_at).counts

          { reporting_site: location }.merge(counts)
        end
    end

    def reporting_delay
      created_at = SolrUtils.indexed_field_name(Incident, :created_at)
      incident_date_derived = SolrUtils.indexed_field_name(Incident, :incident_date_derived)

      days3 = 3 * 24 * 60 * 60 * 1000
      days5 = 5 * 24 * 60 * 60 * 1000
      days14 = 14 * 24 * 60 * 60 * 1000
      days30 = 30 * 24 * 60 * 60 * 1000
      months3 = 30.4167 * 24 * 60 * 60 * 1000

      # For the purposes of this query 1 month is 30.4167 days or
      # 30.4167 * 24 * 60 * 60 * 1000 milliseconds
      search = Incident.search do
        with :created_at, from..to

        adjust_solr_params do |params|
          params[:'facet'] = true
          params[:'facet.query'] = [
            "{!key=0-3days frange u=#{days3}} ms(#{incident_date_derived},#{incident_date_derived})",
            "{!key=4-5days frange l=#{days3 + 1} u=#{days5}} ms(#{incident_date_derived},#{incident_date_derived})",
            "{!key=6-14days frange l=#{days5 + 1} u=#{days14}} ms(#{incident_date_derived},#{incident_date_derived})",
            "{!key=15-30days frange l=#{days14 + 1} u=#{days30}} ms(#{incident_date_derived},#{incident_date_derived})",
            "{!key=1-3months frange l=#{days30 + 1} u=#{months3}} ms(#{incident_date_derived},#{incident_date_derived})",
            "{!key=4months frange l=#{months3 + 1}} ms(#{incident_date_derived},#{incident_date_derived})"
          ]
        end
      end

      @total = search.total
      @results = search.facet_response['facet_queries']
    end

    def service_access_delay
    end

    def assessment_status
    end
    
    def completed_case_safety_plans
    end

    def completed_case_action_plans
    end

    def completed_supervisor_approved_case_action_plans
    end

    def services_provided
    end

    private

    # TODO: Add these to permitted params
    def from
      params[:from]
    end

    def to
      params[:to]
    end
  end
end
