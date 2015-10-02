require_relative '_base'
require_relative 'order_center_private'
require_relative 'order_center_public'

module Otms
  # Order Center business
  class OrderCenter < Base
    include OrderCenterPublic
    include OrderCenterPrivate
    alias_method :select_all_inbox_orders, :select_all_records

    def add_new_order(data_set:nil)
      add_new_orders(1, data_set: data_set)
    end

    def add_new_orders(quantity, data_set:nil)
      data_set ||= data['new']
      data_set['remark'] ||= "CC_#{time_remark}"
      add_record
      save_order(quantity, data_set)
    end

    def release_orders(option:'keep_dates')
      select_all_inbox_orders
      inbox_release.click
      select_release_option(option)
    end
  end
end
