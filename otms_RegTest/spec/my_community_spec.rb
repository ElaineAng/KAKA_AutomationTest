require_relative '../load_path'
require 'lib/login'
require 'lib/my_community'

describe 'My Community' do
  attr_reader :mc

  before do
    @login = Otms::Login.new
    @mc = Otms::MyCommunity.new(@login.sys)
    @login.user_on
    mc.navigate
  end

  after do
    @login.user_off
    @login.close
  end

  it 'can add offline vendor' do
    mc.navigate_sub_tab('my_vendors')
    mc.add_offline_vendor(company_name: 'TESTBJ', company_code: 'TESTBJ')
  end

  it 'can add new tariff' do
    mc.navigate_sub_tab('my_tariffs')
    tariff_name = "TESTBJ TARIFF #{rand(10_000..99_999)}"
    mc.add_new_tariff(
      name: tariff_name,
      partner: 'TESTBJ.*',
      cargo_class: '1. 普通货物',
      trans_unit_class: 'A、散箱，可堆叠，人工装卸货',
      starting_period: Time.new.strftime('%Y.%m.%d'),
      validity_period: (Time.new + 8_640_000).strftime('%Y.%m.%d'),
      transport_mode: '零担',
      unit: '立方米',
      volumetric_conversion: '标准.*',
      kpi: { picked_on_time: 80,
             delivered_on_time: 90,
             c_free_orders: 50,
             d_free_orders: 60 },
      lanes: [{ origin: '2011', destination: '2151',
                rates:
                  { min: 500, _55_less: 30, _55_to_555: 20, _555_more: 10 },
                lead_time: 3 },
              { origin: '2011', destination: '2153',
                rates:
                  { min: 480, _55_less: 28, _55_to_555: 18, _555_more: 8 },
                lead_time: 4 }])
    mc.search_by_tariff_name(tariff_name)
    expect(mc.table.rows.size).to eq(1)
  end

  it 'can delete tariff' do
    mc.navigate_sub_tab('my_tariffs')
    mc.search_by_tariff_name('TESTBJ TARIFF')
    mc.delete_tariff
    expect(mc.table.rows.size).to eq(0)
  end

  it 'can import master data' do
    mc.navigate_sub_tab('my_master_data')
    mc.import_master_data(file: 'bin/data/master_data.xls')
  end

  it 'can add new truck' do
    mc.navigate_sub_tab('my_trucks')
    mc.add_new_truck(
      cargo_class: '1. 普通货物',
      truck_type: '厢式车',
      truck_length: '6.2',
      capacity: '3.5',
      truck_plate: "沪A#{rand(10_000..99_999)}",
      driver_name: '李超',
      driver_mobile: '18601757683')
  end

  it 'can invite new truck' do
    mc.navigate_sub_tab('my_trucks')
    mc.invite_truck
  end

  it 'can add product' do
    mc.navigate_sub_tab('my_master_data')
    mc.navigate_sub_tab('cargo')
    mc.add_new_product(name: "spec_#{rand(10_000..99_999)}", unit: '箱')
  end

  it 'can add location' do
    mc.navigate_sub_tab('my_locations')
    mc.add_new_location(location_name: "闵行#{rand(10_000..99_999)}",
                        third_party_name: "上海#{rand(10_000..99_999)}")
  end
end
