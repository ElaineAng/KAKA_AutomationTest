require_relative '_case'

# Import billing by API

# required data:
# - offline vendor
#     TESTBJ
# - online vendor
#     LICHAOZX
class ApiImportBilling < Otms::Case
  def scenario_0_billing_of_offline_vendor(carrier = 'TESTBJ')
    @original = 'bin/data/import_billing.xml'
    api.carrierCode = carrier
    response = api.import_billing(file: @original)
    results << assert_equal(response.at_css('responseCode').text, '')
  end

  def scenario_1_billing_of_offline_vendor_with_multiple_orders
    response = api.import_billing(request: api.dup_billing_order(api.request),
                                  private_data: { lastRequest: 'false' })
    results << assert_equal(response.at_css('responseCode').text, '')
  end

  def scenario_2_add_offline_order_to_billing_of_offline_vendor
    response = api.import_billing(
      file: @original,
      private_data: {
        name: api.last_billing_name,
        externalOrderNumber: "API_#{api.time_remark}_E3" })
    results << assert_equal(response.at_css('responseCode').text, '')
  end

  def scenario_3_4_5_billing_of_online_vendor
    scenario_0_billing_of_offline_vendor('LICHAOZX')
    scenario_1_billing_of_offline_vendor_with_multiple_orders
    scenario_2_add_offline_order_to_billing_of_offline_vendor
  end

  def report
    @report_step = 'Import billing by API'
  end
end

ApiImportBilling.new.process
