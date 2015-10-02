module Otms
  # Api case set
  module CaseApi
    def future_order_request
      request = api.decode_file(
        api.identified(root: 'orderImportRequest', file: @original))
      api.update_node_to_xml(
        { pickupDate: api.next_work_day.to_s,
          deliveryDate: (api.next_work_day + 3).to_s }, from_hash: request)
    end

    def add_imported_request_to_file
      @imported_file = "#{$cur_path}/bin/data/imported.xml"
      api.write_xml_to_file(@imported_file, xml: api.request)
    end

    def import_file(type:'import_order', file:nil, status:'NOT IMPORTED')
      file ||= @imported_file
      response = api.send(type, request: api.decode_str(str: File.read(file)))
      results << assert_equal(response.at_css('importStatus').text, status)
      File.delete(file)
    end

    def setup_api_device(type)
      instance_variable_set("@#{type}", api.data[type]['address'])
      @device = api.device_id(instance_variable_get("@#{type}"))
    end

    def account_params(type)
      api.symbol_hash(api.data['device'][type])
    end

    def setup_api_account(type)
      account_data = account_params(type)
      account_data[:activationCode] =
        if type == 'xtt'
          api.mail_code
        elsif type == 'driver'
          api.sms_code
        else
          $stdin.gets.chomp
        end
      @account = api.activate(@device, account_data)
    end

    def assert_milestone(order_detail, index)
      result = []
      milestone = order_detail['token']['order']['milestones'][index]
      result << assert_true(
        milestone['actual'] =~
          /#{api.milestone_detail[:actual]}.split('+').join('.\d*\+')/)
      result << assert_equal(
        milestone['updateSource'], expected_source(index))
      result
    end

    def expected_source(index)
      if index == 2
        'XTT_SHIP_FROM'
      else
        index == 3 ? 'XTT_SHIP_TO' : nil
      end
    end
  end
end
