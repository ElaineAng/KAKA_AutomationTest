require_relative '_case'
require_relative '_case_api'

# Update orders by driver API
class ApiDriverUpdate < Otms::Case
  include Otms::CaseApi

  def no_scenario_0_activate_xtt_by_phone
    setup_driver
    results[0] = []
    results[0] << assert_true(@account.include?('account'))
    results[0] << assert_equal(
      @account['account']['connectedPhoneNumbers'], @phone)
  end

  def no_scenario_1_pickup
    response = api.driver_pickup(@device)
    results << assert_milestone(response, 2)
    results[-1] += assert_milestone(api.shipper_order_detail(@device), 2)
  end

  def no_scenario_2_delivery
    response = api.driver_delivery(@device)
    results << assert_milestone(response, 3)
    results[-1] += assert_milestone(api.consignee_order_detail(@device), 3)
  end

  def report
    @report_step = 'Update orders by driver API'
  end

  private

  def setup_driver
    setup_online_order
    setup_api_device('phone')
    setup_api_account('driver')
  end
end

ApiDriverUpdate.new.process
