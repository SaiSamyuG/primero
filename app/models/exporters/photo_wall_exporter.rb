# frozen_string_literal: true

require 'prawn/document'
require 'prawn/measurement_extensions'

module Exporters
  class PhotoWallExporter < BaseExporter
    class << self
      def id
        'photowall'
      end

      def mime_type
        'pdf'
      end

      def supported_models
        [Child]
      end

      def authorize_fields_to_user?
        false
      end
    end

    def initialize(output_file_path = nil, pdf = nil)
      super(output_file_path)
      @pdf = pdf || Prawn::Document.new
    end

    def complete
      buffer.set_encoding(::Encoding::ASCII_8BIT)
      @pdf.render(buffer)
      buffer.rewind
    end

    def export(child_data, _, *_args)
      child_with_photo = child_data.map { |child| child if child.has_photo }.compact
      return no_photo_available(@pdf) if child_with_photo.empty?

      child_with_photo.each do |child|
        add_child_photo(@pdf, child, true)
        @pdf.start_new_page unless child_with_photo.last == child
      rescue StandardError => e
        Rails.logger.error e
      end
    end

    private

    def no_photo_available(pdf)
      pdf.text 'No photos available', size: 40, align: :center, style: :bold
    end

    def add_child_photo(pdf, child, with_full_id = false)
      storage_disk_service = ActiveStorage::Service::DiskService.new(root: Rails.root.to_s + '/storage/')
      render_image(pdf, storage_disk_service.send(:path_for, child.photo.file.blob.key))
      pdf.move_down 25
      pdf.text child.short_id, size: 40, align: :center, style: :bold if with_full_id
      pdf.y -= 3.mm
    end

    def render_image(pdf, data)
      image_bounds = [pdf.bounds.width, pdf.bounds.width]
      pdf.image(
        data,
        position: :center,
        vposition: :top,
        fit: image_bounds
      )
    end

    def flag_if_suspected(pdf, child)
      pdf.text('Flagged as Suspect Record', style: :bold) if child.flag?
    end

    def flag_if_reunited(pdf, child)
      pdf.text('Reunited', style: :bold) if child.reunited?
    end
  end
end
