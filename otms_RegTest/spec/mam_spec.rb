require_relative '../load_path'
require 'lib/login'
require 'lib/mam'

describe 'MAM' do
  attr_reader :mam

  before do
    @login = Otms::Login.new
    @login.navigate_url(@login.mam_url)
    @mam = Otms::Mam.new(@login.sys)
    mam.entry
  end

  after do
    mam.exit
  end

  it 'can generate api key' do
    mam.navigate_sub_tab('otms_companies')
    mam.search_by_code('lichaohz')
    keys = mam.new_api_keys
    p keys
    expect(keys[0][:login]).to be
    expect(keys[0][:password]).to be
  end

  it 'can add custom field' do
    mam.navigate_sub_tab('otms_companies')
    mam.search_by_code('lichaohz')
    mam.add_custom_fields(
      text: [{ index: 1,
               checks: %w(order_header ship_from ship_to order_line
                          order_center dispatch_center billing),
               labels: { english: 'srtf1', chinese: '中文Srtf1' } },
             { index: 2,
               checks: %w(order_header order_center dispatch_center),
               labels: { english: 'srtf2', chinese: '中文Srtf2' } }],
      numeric: [{ index: 1,
                  checks: %w(public order_header order_line
                             order_center dispatch_center),
                  labels: { english: 'srnf1', chinese: '中文Srnf1' } },
                { index: 2,
                  checks: %w(order_header order_center dispatch_center),
                  labels: { english: 'srnf2', chinese: '中文Srnf2' } }],
      enums: [{ index: 1,
                checks: %w(public order_header order_line
                           order_center dispatch_center track_and_trace),
                labels:
                  { english: 'sref1',
                    chinese: '中文Sref1',
                    options:
                      [{ english: 'sref1a1', chinese: '中文Sref1a1',
                         logical: '备注11' },
                       { english: 'sref1a2', chinese: '中文Sref1a2',
                         logical: '备注12' }] } },
              { index: 2,
                checks: %w(order_header order_center dispatch_center),
                labels:
                  { english: 'sref2',
                    chinese: '中文Sref2',
                    options:
                      [{ english: 'sref2a1', chinese: '中文Sref2a1',
                         logical: '备注21' },
                       { english: 'sref2a2', chinese: '中文Sref2a2',
                         logical: '备注22' }] } }])
  end
end
