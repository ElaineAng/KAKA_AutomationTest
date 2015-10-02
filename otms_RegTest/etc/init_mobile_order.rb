require_relative '_required'
require 'bin/_case'
require 'lib/mam'
require 'headless'
require '../load_path'

# Initialize orders which have dispatched to XTT app and Driver app
class InitMobileOrder < Otms::Case
  attr_accessor :username, :password

  def report
    @report_step = 'initialize mobile orders'
  end

  def before_all
    report
    @results = []
    @api = Otms::Api.new(report: @report_file) unless api
    initialize_otms unless login
  end

  def after_all
    report
    output_result
    login.user_off if login
  end

  def scenario_0_create_new_api_key
    Watir.default_timeout = 180
    if YAML.load_file('key.yml')[username]
      puts "  -> will be skipped for #{username}."
      @new_api_key = YAML.load_file('key.yml')[username]['api']
    else
      set_up_mam
      return_otms
    end
    results << 'Pass'
  end

  def scenario_1_import_order
    results[0] = []
    response = api.import_orders(
      50,
      file: 'etc/init_mobile_order.xml',
      login: @new_api_key['username'],
      password: @new_api_key['password'])
    response.each do |r|
      results[0] << assert_equal(r.at_css('importStatus').text, 'DISPATCHED')
    end
  end

  def scenario_2_dispatch_order
    print '  -> dispatching online order to truck...'
    switch_user('sp')
    setup_order_center(new_order: false)
    setup_dispatch_center('truck', batch: true)
    results << 'Pass'
  end

  private

  def entry_mam(username)
    @mam = Otms::Mam.new(login.sys)
    login.navigate_url(login.mam_url)
    @mam.entry
    @mam.navigate_sub_tab('otms_companies')
    @mam.search_by_code(username)
  end

  def write_out_key
    keys = @mam.new_api_keys
    new_key = @mam.write_out_key_file(
      data_set: @mam.key_data_hash(
        username, username, password, keys[0][:login], keys[0][:password]))
    new_key
  end

  def verify_key(role)
    results[0] = []
    results[0] << assert_true(role['account']['username'])
    results[0] << assert_true(role['api']['username'])
  end

  def set_up_mam
    entry_mam(username)
    @mam.configure_access('auto_process')
    new_key = write_out_key
    @new_api_key = new_key[username]['api']
    verify_key(new_key[username])
    @mam.logout
  end

  def return_otms
    login.navigate_url(login.otms_url)
    login.data = login.initialize_data('key.yml')
  end
end

users = YAML.load_file($cur_path+'etc/users.yml')
shippers = users[:sr][:username].reverse
orders = users[:orders]
@order_count = 0

# patch color methods to String
class String
  include Term::ANSIColor
end

loop do
  begin
    @shipper = shippers.pop
    break unless @shipper
    init_process = lambda do
      @init = InitMobileOrder.new
      @init.password = users[:sr][:password]
      @init.username = @shipper
      @rest_orders ||= orders
      (@rest_orders / 50).times do
        @init.process
        @order_count += 50
        puts "\n  -> dispatched #{@order_count} orders from #{@shipper}\n".green
      end
      @init.login.close
      @rest_orders = nil
    end
    ARGV[-1] == '--show' ? init_process.call : Headless.ly { init_process.call }
  rescue StandardError => e
    puts e
    if @order_count < orders
      shippers.push(@shipper)
      @rest_orders = orders - @order_count
    end
    next
  end
end
