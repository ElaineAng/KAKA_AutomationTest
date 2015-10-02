require_relative '../lib/api'
require_relative '../lib/login'
require_relative '../lib/order_center'
require_relative '../lib/dispatch_center'

module Otms

  module KAKAMethods

    API = Otms::Api.new
    LOGIN = Otms::Login.new
    OC = Otms::OrderCenter.new(LOGIN.sys)
    DC = Otms::DispatchCenter.new(LOGIN.sys)

    def import_order_for_kaka (original, n)
      if n==1 then
        API.import_order(file: original)
      else
        API.import_orders(n, file: original)
      end
    end

    def release_order_for_kaka(remark:nil)
      LOGIN.user_on
      OC.navigate
      OC.search_by_remark(remark)
      OC.release_orders
    end

    def dispatch_order_for_kaka(remark:nil)
      DC.navigate
      DC.search_by_released_orders_remark(remark)
      DC.assign_truck
      DC.navigate_sub_tab('under_allocation', index: 1)
      DC.search_by_under_allocation_remark(remark)
      DC.confirm_assigned
    end

  end
end
