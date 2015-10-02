require_relative '_base'
require_relative 'dispatch_center_private'
require_relative 'dispatch_center_public'

module Otms
  # Dispatch Center business
  class DispatchCenter < Base
    include DispatchCenterPublic
    include DispatchCenterPrivate

    def assign_online_vendor(data_set = {})
      select_every_row do
        select_my_truck.wait_until_present
        select_expected_tariff(data_set[:tariff])
        select_my_truck.wait_while_present
      end
    end

    def assign_truck(data_set = {})
      select_all_released_orders
      select_my_truck.when_present.click
      if data_set[:driver] && data_set[:plate]
        select_expected_truck(data_set[:driver], data_set[:plate])
      else
        select_first_truck
      end
    end

    def confirm_assigned
      under_allocation_table.rows.size.times do
        under_allocation_table.[](0).[](0).img.click
        wait_loading
        popup_content.wait_while_present
        sleep 3
      end
    end

    def batch_confirm_assigned
      under_allocation_batch_allocation.click
      wait_loading
      confirm_assigned
    end
  end
end
