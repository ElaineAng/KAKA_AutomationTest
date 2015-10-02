require_relative '../load_path'
require 'lib/login'
require 'lib/order_center'
require 'lib/dispatch_center'

describe 'Dispatch Center' do
  attr_reader :login, :oc, :dc

  before do
    @login = Otms::Login.new
    @oc = Otms::OrderCenter.new(login.sys)
    @dc = Otms::DispatchCenter.new(login.sys)
  end

  after do
    login.user_off
    login.close
  end

  def setup_order_center
    login.user_on
    oc.navigate
    oc.add_new_order
    oc.search_by_remark(oc.data['new']['remark'])
    oc.release_orders
  end

  def setup
    dc.navigate
    dc.search_by_released_orders_remark(oc.data['new']['remark'])

  end

  it 'can assign to an online vendor' do
    setup_order_center
    setup
    dc.assign_online_vendor(tariff: dc.data['sr']['tariff'])
  end

  it 'can assign to a truck' do
    setup_order_center
    setup
    dc.assign_truck
  end

  it 'can confirm assigned' do
    setup_order_center
    setup
    dc.assign_truck
    dc.navigate_sub_tab('under_allocation', index: 1)
    dc.search_by_under_allocation_remark(oc.data['new']['remark'])
    dc.confirm_assigned
  end

  it 'can batch confirm assigned' do
    setup_order_center
    setup
    dc.assign_truck
    dc.navigate_sub_tab('under_allocation', index: 1)
    dc.batch_confirm_assigned
  end
end
