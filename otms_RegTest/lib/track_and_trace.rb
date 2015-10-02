require_relative '_base'

module Otms
  # Track & Trace business
  class TrackAndTrace < Base
    %w(erp remark).each do |field|
      define_method("search_by_#{field}") do |text, role, timeout:nil|
        load_filters(filter_file, parent: @sys, index: 0)
        search(text, text_object: send("tt_#{role}_#{field}"), timeout: timeout)
      end
    end

    def batch_pickup(date:nil)
      batch_update_milestone('pickup', date)
    end

    def batch_delivery(date:nil)
      batch_update_milestone('delivery', date)
    end

    def batch_update_milestone(action, data_set)
      send("tabs_button_bulk_#{action}").click
      popup_content.wait_until_present
      first_text_field.set(data_set) if data_set
      first_button.click
      popup_message.wait_until_present
      wait_while_message
    end
  end
end
