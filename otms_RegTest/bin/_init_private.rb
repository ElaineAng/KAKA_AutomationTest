# private methods for Init
module InitPrivate
  private

  def entry_mam(username)
    @mam = Otms::Mam.new(login.sys)
    login.navigate_url(login.mam_url)
    mam.entry
    mam.navigate_sub_tab('otms_companies')
    mam.search_by_code(username)
  end

  def create_new_api_key(role, username, password)
    keys = mam.new_api_keys
    new_key = mam.write_out_key_file(
      data_set: mam.key_data_hash(
        role, username, password, keys[0][:login], keys[0][:password]))
    verify_key(new_key[role])
  end

  def verify_key(role)
    results[0] = []
    results[0] << assert_true(role['account']['username'])
    results[0] << assert_true(role['api']['username'])
  end

  def entry_my_master_data(role)
    login.data = login.initialize_data('key.yml')
    login.user_on(role: role)
    mc.navigate
    mc.navigate_sub_tab('my_master_data')
  end

  def tariff_data
    init = mc.data[:init]
    init.merge!(type: mc.data[:init_sp][:type]) unless @role == 'sr'
    init.merge!(tariff_periods)
  end

  def tariff_periods
    { starting_period: mc.next_work_day.strftime('%Y.%m.%d'),
      validity_period: (mc.next_work_day + 100).strftime('%Y.%m.%d') }
  end

  def add_new_tariff
    mc.navigate_sub_tab('my_tariffs')
    mc.add_new_tariff(tariff_data)
    mc.exit_tariff
    mc.search_by_tariff_name('TESTBJ INIT TARIFF')
  end

  def custom_fields
    text_custom_fields.merge(numeric_custom_fields).merge(enums_custom_fields)
  end

  def text_custom_fields
    { text: [{ index: 1,
               checks:
                 %w(public order_header
                    order_center dispatch_center track_and_trace billing),
               labels: { english: 'srtf1', chinese: '中文Srtf1' } },
             { index: 2,
               checks:
                 %w(order_header
                    order_center dispatch_center track_and_trace billing),
               labels: { english: 'srtf2', chinese: '中文Srtf2' } }] }
  end

  def numeric_custom_fields
    { numeric: [{ index: 1,
                  checks:
                    %w(public order_header
                       order_center dispatch_center track_and_trace billing),
                  labels: { english: 'srnf1', chinese: '中文Srnf1' } },
                { index: 2,
                  checks:
                    %w(order_header
                       order_center dispatch_center track_and_trace billing),
                  labels: { english: 'srnf2', chinese: '中文Srnf2' } }] }
  end

  def enums_custom_fields
    { enums: [enums_custom_fields_1, enums_custom_fields_2] }
  end

  def enums_custom_fields_1
    { index: 1,
      checks:
        %w(public order_header
           order_center dispatch_center track_and_trace billing),
      labels: { english: 'sref1', chinese: '中文Sref1',
                options:
                  [{ english: 'sref1a1', chinese: '中文Sref1a1',
                     logical: '备注11' },
                   { english: 'sref1a2', chinese: '中文Sref1a2',
                     logical: '备注12' }] } }
  end

  def enums_custom_fields_2
    { index: 2,
      checks:
        %w(order_header
           order_center dispatch_center track_and_trace billing),
      labels: { english: 'sref2', chinese: '中文Sref2',
                options:
                  [{ english: 'sref2a1', chinese: '中文Sref2a1',
                     logical: '备注21' },
                   { english: 'sref2a2', chinese: '中文Sref2a2',
                     logical: '备注22' }] } }
  end
end
