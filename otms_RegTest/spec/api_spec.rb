require_relative '../load_path'
require 'lib/api'
require 'bin/_case'

describe 'oTMS API' do
  attr_reader :api

  before do
    @api = Otms::Api.new
  end

  it 'can import order' do
    response = api.import_order(file: 'bin/data/import_order.xml')
    expect(response.at_css('importStatus').text).to eq('INBOX')
  end

  it 'can import 2 orders' do
    response = api.import_orders(2, file: 'bin/data/import_order.xml')
    response.each { |r| expect(r.at_css('importStatus').text).to eq('INBOX') }
  end

  it 'can import billing' do
    response = api.import_billing(file: 'bin/data/import_billing.xml',
                                  private_data: { carrierCode: 'TESTBJ' })
    expect(response.at_css('responseCode').text).to eq('')
  end

  it 'can import 2 billings' do
    response = api.import_billings(2,
                                   file: 'bin/data/import_billing.xml',
                                   private_data: { carrierCode: 'TESTBJ' })
    response.each { |r| expect(r.at_css('responseCode').text).to eq('') }
  end

  it 'can import ship point' do
    response = api.import_ship_point(file: 'bin/data/import_ship_point.xml')
    expect(response.at_css('importStatus').text).to eq('ADDED')
  end

  it 'can remove ship point' do
    imported = api.import_ship_point(file: 'bin/data/import_ship_point.xml')
    response = api.remove_ship_point(
      file: 'bin/data/remove_ship_point.xml',
      clientReferenceNumber: imported.at_css('clientReferenceNumber').text,
      type: 0)
    expect(response.at_css('importStatus').text).to eq('REMOVED')
  end

  it 'can get device id' do
    response = api.device_id('otmst@sina.cn')
    expect(response.class).to eq(String)
    expect(response.size).to eq(24)
  end

  def activate_device
    @device_id = api.device_id('otmst@sina.cn')
    code = api.mail_code
    api.activate(@device_id,
                 activationCode: code,
                 appName: 'driver-test',
                 appVersion: '10.0.0',
                 osName: 'BlackBerry',
                 osVersion: '11')
  end

  def dispatched_online_order
    Otms::Case.new.dispatched_online_order
  end

  it 'can activate device' do
    response = activate_device
    expect(response).to include('account')
    expect(response['account']['connectedEmailAddresses'])
      .to eq('otmst@sina.cn')
  end

  it 'can pickup' do
    dispatched_online_order
    activate_device
    response = api.pickup(@device_id, comments: 'pickup spec', stars: 4)
    milestone = response['token']['order']['milestones'][2]
    expect(milestone['actual']).to eq(api.milestone_detail[:actual])
    expect(milestone['updateSource']).to eq('XTT_SHIP_FROM')
  end

  it 'can delivery' do
    activate_device
    response = api.delivery(@device_id, comments: 'delivery spec', stars: 5)
    milestone = response['token']['order']['milestones'][3]
    expect(milestone['actual']).to eq(api.milestone_detail[:actual])
    expect(milestone['updateSource']).to eq('XTT_SHIP_TO')
  end

  it 'can upload epod' do
    activate_device
    order_no =
      api.consignee_order_detail(@device_id)['token']['order']['orderNumber']
    api.upload_epod(@device_id, file: 'bin/data/xtt.jpg')
    shipper_milestone =
      api.shipper_order_detail(@device_id)['token']['order']['milestones'][4]
    consignee_milestone =
      api.consignee_order_detail(@device_id)['token']['order']['milestones'][4]
    expect(shipper_milestone).to include('attachments')
    expect(shipper_milestone['attachments']['fileName'])
      .to eq("#{order_no}#{api.requested_file}")
    expect(consignee_milestone).to include('attachments')
    expect(consignee_milestone['attachments']['fileName'])
      .to eq("#{order_no}#{api.requested_file}")
  end
end
