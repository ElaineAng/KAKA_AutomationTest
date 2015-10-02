module Otms
  # public methods for Otms::DispatchCenter
  module DispatchCenterPublic
    %w(released_orders under_allocation origin_split_box shipment_outbox)
      .each do |t|
      define_method("search_by_#{t}_remark") do |text, timeout:nil|
        search(text, text_object: send("dc_#{t}_remark"), timeout: timeout)
      end
    end

    def select_all_released_orders
      select_all_records(col: 1)
    end
  end
end
