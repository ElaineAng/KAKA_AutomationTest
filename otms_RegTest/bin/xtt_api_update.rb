require_relative '_case'
require_relative '_case_api'

# Update orders by XTT API
class ApiXttUpdate < Otms::Case
  include Otms::CaseApi

  def scenario_0_activate_xtt_by_mail
    setup_xtt
    results[0] = []
    results[0] << assert_true(@account.include?('account'))
    results[0] << assert_equal(
      @account['account']['connectedEmailAddresses'], @mail)
  end

  def scenario_1_shipper_cannot_pickup
    response = api.pickup(@device)
    results << assert_equal(response, 500)
  end

  def scenario_2_consignee_cannot_pickup
    response = api.pickup(@device, token: api.consignee_token(@device))
    results << assert_equal(response, 403)
  end

  def scenario_3_shipper_pickup(online: true)
    response = pickup(online)
    results << assert_milestone(response, 2)
    results[-1] += assert_milestone(api.shipper_order_detail(@device), 2)
  end

  def scenario_4_shipper_cannot_delivery
    response = api.delivery(@device, token: api.shipper_token(@device))
    results << assert_equal(response, 403)
  end

  def scenario_5_consignee_delivery
    response = api.delivery(@device)
    results << assert_milestone(response, 3)
    results[-1] += assert_milestone(api.consignee_order_detail(@device), 3)
  end

  def scenario_6_shipper_cannot_upload_epod
    response = api.upload_epod(
      @device, file: api.data['file'], token: api.shipper_token(@device))
    results << assert_equal(response, 403)
  end

  def scenario_7_consignee_upload_epod
    api.upload_epod(@device, file: api.data['file'])
    results << assert_attachment('shipper')
    results[-1] += assert_attachment('consignee')
  end

  def scenario_8_update_offline_order
    dispatch_offline_order
    print '  -> updating offline order...'
    5.times { |s| s == 1 ? run_scenario_3_by_offline : run_scenario(s + 2) }
    print "done.\n"
  end

  def report
    @report_step = 'Update orders by XTT API'
  end

  private

  def setup_xtt
    setup_online_order
    setup_api_device('mail')
    setup_api_account('xtt')
  end

  def pickup(online)
    dispatch_online_order if online
    api.pickup(@device)
  end

  def assert_attachment(role)
    result = []
    order = api.send("#{role}_order_detail", @device)['token']['order']
    order_no = order['orderNumber']
    milestone = order['milestones'][4]
    result << assert_equal(milestone['attachments']['fileName'],
                           "#{order_no}#{api.requested_file}")
    result
  end

  def run_scenario_3_by_offline
    send(methods.select { |m| m =~ /scenario_3.*/ }[0], online: false)
  end
end

ApiXttUpdate.new.process
