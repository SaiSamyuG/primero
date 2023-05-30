# frozen_string_literal: true

# Class to export the Incidents Subreport
class Exporters::IncidentsSubreportExporter < Exporters::SubreportExporter
  MERGED_INDICATORS = %w[total gbv_sexual_violence gbv_previous_incidents].freeze

  def write_export
    write_header
    write_params
    write_generated_on
    write_merged_indicator
    write_indicators
  end

  def write_merged_indicator
    merged_indicator = merged_indicator_class.new(
      key: 'combined',
      values: data,
      worksheet: worksheet,
      current_row: current_row,
      grouped_by: grouped_by,
      formats: formats,
      managed_report: managed_report,
      locale: locale,
      merged_indicators: MERGED_INDICATORS
    )
    merged_indicator.write
    self.current_row = merged_indicator.current_row
  end

  def merged_indicator_class
    return Exporters::GroupedMergedIndicatorExporter if grouped_by.present?

    Exporters::MergedIndicatorExporter
  end

  def write_indicators
    transform_entries.each do |(indicator_key, indicator_values)|
      next if MERGED_INDICATORS.include?(indicator_key)

      indicator_exporter = build_indicator_exporter(indicator_key, indicator_values)
      indicator_exporter.write
      self.current_row = indicator_exporter.current_row
    end
  end
end
