require_relative '_case'
require_relative '_init_private'
require 'lib/mam'
require 'headless'

# Initialize all required test data
class Init < Otms::Case
  include InitPrivate
  attr_reader :mam

  def scenario_0_create_new_api_key
    @role = ARGV[0]
    username = ARGV[1]
    password = ARGV[2]
    entry_mam(username)
    create_new_api_key(@role, username, password)
  end

  def scenario_1_add_custom_fields
    mam.add_custom_fields(custom_fields)
    mam.logout
    login.navigate_url(login.otms_url)
    results << 'Pass'
  rescue
    results << 'Fail'
  end

  def scenario_2_add_ship_from
    unless @role == 'sr'
      puts '  -> will not do in sp.'
      return results << 'Pass'
    end
    response = api.import_ship_point(
      key_type: api.send("#{@role}_key"), file: 'bin/data/init_ship_from.xml')
    results << assert_true(response.at_css('importStatus').text)
  end

  def scenario_3_add_ship_to
    unless @role == 'sr'
      puts '  -> will not do in sp.'
      return results << 'Pass'
    end
    response =
      api.import_ship_point(
        key_type: api.send("#{@role}_key"),
        file: 'bin/data/init_ship_to.xml', type: 1)
    results << assert_true(response.at_css('importStatus').text)
  end

  def add_new_product
    mc.navigate_sub_tab('cargo')
    mc.add_new_product(
      name: '苹果', stackable: '不可堆叠', unit: '箱',
      unit_length: 3, unit_height: 0.5, unit_width: 2, unit_weight: 500,
      external_id: 'A')
  end

  def scenario_4_add_product
    entry_my_master_data(@role)
    unless @role == 'sr'
      puts '  -> will not do in sp.'
      return results << 'Pass'
    end
    add_new_product
    results << assert_true(mc.table.rows.size > 0)
  end

  def meta_truck_data
    { cargo_class: '1. 普通货物', truck_type: '厢式车',
      truck_length: '6.2', capacity: '3.5',
      truck_plate: "沪A#{rand(10_000..99_999)}",
      driver_name: '李超', driver_mobile: '18601757683' }
  end

  def string_hash(truck_data)
    Hash[truck_data.reject { |k, _v| k == :parent }
      .map { |(k, v)| [k.to_s, v] }]
  end

  def add_new_truck(truck_data)
    mc.navigate_sub_tab('my_trucks')
    mc.add_new_truck(truck_data)
    mc.search_by_truck_plate(truck_data[:truck_plate])
    mc.invite_truck
    mc.write_append_yaml(
      'key.yml', @role, 'truck' => string_hash(truck_data))
  end

  def scenario_5_add_new_truck
    truck_data = meta_truck_data
    add_new_truck(truck_data)
    mc.copy_file(from: 'key.yml', to: 'init_data.yml')
    results << assert_true(mc.table.rows.size > 0)
  end

  def scenario_6_add_location
    mc.navigate_sub_tab('my_locations')
    %w(上海总部 浦东分部).each do |var|
      mc.add_new_location(location_name: var)
      mc.exit_record
    end
    results << assert_true(mc.table.rows.size >= 2)
  end

  def scenario_7_add_offline_vendor
    vendor_data = { company_name: 'TESTBJ', company_code: 'TESTBJ' }
    if @role == 'sr'
      mod = 'my_vendors'
    else
      mod = 'my_network'
      vendor_data.merge!(role: '承运商')
    end
    mc.navigate_sub_tab(mod)
    mc.add_offline_vendor(vendor_data)
    results << assert_true(mc.table.rows.size > 0)
  end

  def scenario_8_add_offline_client
    if @role == 'sr'
      puts '  -> will not do in sr.'
      return results << 'Pass'
    end
    client_data = { role: '客户', company_name: 'oApple', company_code: 'oApple' }
    mc.add_offline_client(client_data)
    results << assert_true(mc.table.rows.size > 0)
  end

  def scenario_9_add_offline_tariff
    add_new_tariff
    results << assert_equal(mc.table.rows.size, 1)
  end

  def report
    @report_step = 'Initialize all required test data'
  end
end

Headless.ly { Init.new.process }
