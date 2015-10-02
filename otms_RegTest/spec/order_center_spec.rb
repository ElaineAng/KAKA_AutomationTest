require_relative '../load_path'
require 'lib/login'
require 'lib/order_center'

describe 'Order Center' do
  attr_reader :login, :oc

  before do
    @login = Otms::Login.new
    @oc = Otms::OrderCenter.new(login.sys)
  end

  after do
    login.user_off
    login.close
  end

  it 'can add one order by sr' do
    login.user_on
    oc.navigate
    oc.add_new_order
  end

  it 'can add one order by sp' do
    login.user_on(role: 'sp')
    oc.navigate
    oc.add_new_order(data_set: oc.data['sp_new'])
  end

  it 'can add two orders by sr' do
    login.user_on
    oc.navigate
    oc.add_new_orders(2)
  end

  it 'can add two orders by sp' do
    login.user_on(role: 'sp')
    oc.navigate
    oc.add_new_orders(2, data_set: oc.data['sp_new'])
  end

  it 'can assert order preview' do
    login.user_on
    oc.navigate
    oc.add_new_order
    oc.search_by_remark(oc.data['new']['remark'])
    expected = oc.data['new']
    expected.delete('suggested_tariff')
    expected['ship_from'].gsub!(%r{\s*\/.*}, '')
    expected['ship_to'].gsub!(%r{\s*\/.*}, '')
    oc.assert_order_preview(expected)
  end

  it 'can release order' do
    login.user_on
    oc.navigate
    oc.release_orders
  end
end
