require 'lib/login'
require 'lib/order_center'
require 'lib/dispatch_center'
require 'lib/my_community'
require 'lib/track_and_trace'

module Otms
  # Business set
  module Workflow
    attr_reader :login, :oc, :dc, :tt, :mc

    def initialize_otms
      @login = Otms::Login.new
      @oc = Otms::OrderCenter.new(login.sys, report: @report_file)
      @dc = Otms::DispatchCenter.new(login.sys, report: @report_file)
      @tt = Otms::TrackAndTrace.new(login.sys, report: @report_file)
      @mc = Otms::MyCommunity.new(login.sys, report: @report_file)
    end

    def dispatched_online_order
      setup_online_order
      dispatch_online_order
    end

    def dispatched_offline_order
      initialize_otms
      dispatch_offline_order
    end

    def batch_pickup
      tt.navigate
      tt.navigate_sub_tab('dispatched')
      tt.batch_pickup
    end

    def batch_delivery
      tt.navigate_sub_tab('picked')
      tt.batch_delivery
    end

    def exit
      login.user_off
      login.close
    end

    def setup_online_order
      initialize_otms
      setup_sr
    end

    def dispatch_online_order
      setup_sp
    end

    def dispatch_offline_order(new_order:true, truck_data:nil, batch:false)
      print '  -> dispatching offline order to truck..'
      dispatch_order_to_truck(
        'sr', new_order: new_order, truck_data: truck_data, batch: batch)
    end

    def setup_sr
      print '  -> dispatching online order to sp...'
      switch_user('sr')
      setup_order_center(new_order: true)
      setup_dispatch_center('online_vendor', tariff: dc.data['sr']['tariff'])
    end

    def setup_sp
      print '  -> dispatching online order to truck...'
      dispatch_order_to_truck('sp', new_order: false)
    end

    def dispatch_order_to_truck(
      role, new_order:nil, remark:nil, truck_data:nil, batch:false)
      truck_data ||= dc.data[role]['truck']
      switch_user(role)
      setup_order_center(new_order: new_order, remark: remark)
      setup_dispatch_center(
        'truck',
        driver: truck_data['driver'],
        plate: truck_data['plate'],
        batch: batch)
    end

    def switch_user(role)
      login.user_off if login.role && login.role != role
      login.user_on(role: role)
    end

    def setup_order_center(new_order:nil, remark:nil)
      @otms_remark = remark if remark
      oc.navigate
      if new_order
        oc.add_new_order
        @otms_remark = oc.data['new']['remark']
      end
      oc.search_by_remark(@otms_remark)
      oc.release_orders
    end

    def setup_dispatch_center(vendor, data_set = {})
      dc.navigate
      dc.search_by_released_orders_remark(@otms_remark)
      dc.send("assign_#{vendor}", data_set)
      setup_assigned(data_set[:batch])
      print "done.\n"
    end

    def setup_assigned(batch)
      dc.navigate_sub_tab('under_allocation', index: 1)
      if batch
        action = 'batch_'
      else
        action = ''
        dc.search_by_under_allocation_remark(@otms_remark)
      end
      dc.send("#{action}confirm_assigned")
    end
  end
end
