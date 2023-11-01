# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Job that bulk assign records to an user
class BulkAssignRecordsJob < ApplicationJob
  queue_as :long_running_process

  def perform(args = {})
    args[:records].each do |record|
      Assign.create!(
        record:, transitioned_to: args[:transitioned_to], transitioned_by: args[:transitioned_by], notes: args[:notes]
      )
    rescue StandardError => e
      Rails.logger.error e.message
      next
    end
  end
end
