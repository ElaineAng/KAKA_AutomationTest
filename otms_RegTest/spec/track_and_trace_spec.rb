require_relative '../load_path'
require 'lib/login'
require 'lib/order_center'
require 'lib/dispatch_center'
require 'lib/track_and_trace'

describe 'Track & Trace' do
  attr_reader :tt
  before do
    @login = Otms::Login.new
    @oc = Otms::OrderCenter.new(@login.sys)
    @dc = Otms::DispatchCenter.new(@login.sys)
    @tt = Otms::TrackAndTrace.new(@login.sys)
    @login.user_on
    @oc.navigate
    @oc.add_new_order
    @remark = @oc.data['new']['remark']
    @oc.search_by_remark(@remark)
    @oc.release_orders
    @dc.navigate
    @dc.search_by_released_orders_remark(@remark)
    @dc.assign_truck
    @dc.navigate_sub_tab('under_allocation', index: 1)
    @dc.search_by_under_allocation_remark(@remark)
    @dc.confirm_assigned
  end

  after do
    @login.user_off
    @login.close
  end

  it 'can batch pickup' do
    tt.navigate
    tt.navigate_sub_tab('dispatched')
    tt.search_by_remark(@remark, @login.role)
    tt.batch_pickup
  end

  it 'can batch delivery' do
    tt.navigate
    tt.navigate_sub_tab('dispatched')
    tt.search_by_remark(@remark, @login.role)
    tt.batch_pickup
    tt.navigate_sub_tab('picked')
    tt.search_by_remark(@remark, @login.role)
    tt.batch_delivery
  end
end
