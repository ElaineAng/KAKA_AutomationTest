require 'json'

module Otms
  # public methods for Otms::Api
  module ApiPublic
    attr_reader :request, :milestone_detail, :requested_file
    attr_accessor :carrierCode

    %w(api sp).each do |var|
      define_method("#{var}_key") do
        key_data = initialize_data("#{$cur_path}/key.yml")
        var = var == 'api' ? 'sr' : var
        { login: key_data[var]['api']['username'],
          password: key_data[var]['api']['password'] }
      end
    end

    alias_method :sr_key, :api_key

    def request_method(path, str, method, type)
      @request = str
      puts "\n  -> Request:\n#{str}" if ARGV[-1] == '--debug'
      response = if method == 'delete'
                   execute_request(path, str, method, type)
                 else
                   resource(path).send(method, str, content_type: type)
                 end
      puts "\n  -> Response:\n#{response}" if ARGV[-1] == '--debug'
      format_response(response, type)
    end

    def format_response(response, type)
      if type.include?('xml')
        noko_xml(response)
      else
        type.include?('json') ? JSON.parse(response) : response
      end
    end

    { put_xml: 'application/xml; charset=utf-8',
      delete_xml: 'application/xml; charset=utf-8',
      put_text: 'text/plain; charset=utf-8',
      put_json: 'application/json; charset=utf-8',
      post_json: 'application/json; charset=utf-8' }.each do |key, value|
        define_method("request_#{key}") do |path, str|
          request_method(path, str, key.to_s.split('_').first, value)
        end
      end

    %w(json).each do |var|
      define_method("request_get_#{var}") do |path|
        response = resource(path).get
        puts response if ARGV[-1] == '--debug'
        format_response(response, var)
      end
    end

    def request_put_file(path, file)
      @requested_file = file.split('/')[-1]
      response = resource(path).put(
        File.read(file),
        content_type: 'application/x-www-form-urlencoded; charset=UTF-8',
        content_disposition: "attachment; filename=#{requested_file}")
      puts response if ARGV[-1] == '--debug'
      format_response(response, 'json')
    end

    def noko_xml(xml_str)
      Nokogiri::XML(xml_str)
    end

    def noko_xml_file(file)
      noko_xml(File.read(file))
    end

    def order_remark
      remark = noko_xml(request).at_css('clientReferenceNumber').text.split('_')
      remark.pop if remark.size > 2
      remark.join('_')
    end

    def ship_point_nodes
      %i(clientCode clientReferenceNumber type externalId)
    end

    def update_ship_point_type(data_set)
      data_set[:type] ||= 0
      update_nodes(%i(type clientCode), data_set)
    end

    def update_nodes(nodes, data_set = {})
      data_set.select { |k, _v| nodes.include?(k) }.each do |k, v|
        xml = noko_xml(data_set[:request])
        xml.at_css(k.to_s).content = v
        data_set[:request] = xml.to_xml
      end
      data_set
    end

    def decode_str(xml_hash = {})
      xml = noko_xml(xml_hash[:str])
      if xml_hash[:key] && xml_hash[:root]
        xml_hash[:key].keys.each do |var|
          xml.at_css(xml_hash[:root])[var.to_s] = xml_hash[:key][var]
        end
      end
      xml.to_xml
    end

    def decode_file(data_set = {})
      decode_str(
        str: replaced(File.read(data_set[:file]), data_set[:seq]),
        key: data_set.select { |k, _v| data_set[:key_type].include?(k) },
        root: data_set[:root])
    end

    def identified(data_set = {})
      data_set[:key_type] ||= api_key
      data_set[:key_type].keys.each do |var|
        data_set[var] ||= data_set[:key_type][var]
      end
      data_set
    end

    def write_xml_to_file(file, xml:nil, timeout:nil)
      sleep timeout.to_i
      xml = xml.is_a?(Nokogiri::XML::Document) ? xml.to_xml : xml
      File.open(file, 'w+:UTF-8') { |f| f.puts xml }
    end

    def add_node_to_xml(node_hash, from_hash:nil)
      xml = noko_xml(from_hash)
      node_hash.each do |k, v|
        node = xml.at_css(v[:before])
        new_node = Nokogiri::XML::Node.new k.to_s, xml
        new_node.content = v[:value]
        node.add_previous_sibling(new_node)
      end
      xml.to_xml
    end

    def add_node(node_hash, from_file:nil, to_file:nil)
      xml = noko_xml(File.read(from_file))
      node_hash.each do |k, v|
        node = xml.at_css(v[:sibling])
        new_node = Nokogiri::XML::Node.new k.to_s, xml
        new_node.content = v[:value]
        node.add_next_sibling(new_node)
      end
      write_xml_to_file(to_file, xml: xml, timeout: 1)
    end

    def add_child_to_xml(node_hash, from_hash:nil)
      xml = noko_xml(from_hash)
      node_hash.each do |k, v|
        node = xml.at_css(v[:parent])
        new_node = Nokogiri::XML::Node.new k.to_s, xml
        new_node.content = v[:value]
        node.add_child(new_node)
      end
      xml.to_xml
    end

    def update_node_to_xml(node_hash, from_hash:nil)
      xml = noko_xml(from_hash)
      node_hash.each { |k, v| xml.at_css(k.to_s).content = v }
      xml.to_xml
    end

    def update_node(node_hash, from_file:nil, to_file: nil)
      xml = noko_xml(File.read(from_file))
      node_hash.each { |k, v| xml.at_css(k.to_s).content = v }
      write_xml_to_file(to_file, xml: xml, timeout: 1)
    end

    def dup_order(xml)
      order = xml.at_css('order')
      new_order = order.dup
      new_order['sequence'] = order['sequence'].to_i + 1
      new_order.at_css('erpNumber').content =
        "#{order.at_css('erpNumber').text}-#{new_order['sequence']}"
      order.add_next_sibling(new_order)
      xml
    end

    def dup_order_to_file(from_file:nil, to_file:nil)
      write_xml_to_file(to_file,
                        xml: dup_order(noko_xml(File.read(from_file))),
                        timeout: 1)
    end

    def default_billing_data(str, data_set)
      xml = noko_xml(str)
      data_set[:carrierCode] ||= @carrierCode
      data_set[:name] ||= "API_#{time_remark}"
      data_set[:externalOrderNumber] ||= "#{data_set[:name]}_E1"
      data_set.each { |k, v| xml.at_css(k.to_s).content = v }
      xml.to_xml
    end

    def dup_billing_order(xml_str)
      xml_str = noko_xml(xml_str)
      order = xml_str.at_css('orders')
      new_order = order.dup
      order_no = order.at_css('externalOrderNumber').text
      new_order_no = order_no.gsub(/.$/, (order_no[-1].to_i + 1).to_s)
      new_order.at_css('externalOrderNumber').content = new_order_no
      order.add_next_sibling(new_order)
      xml_str.to_xml
    end

    def last_billing_name
      noko_xml(request).at_css('name').text
    end

    def device_path(id)
      "#{xtt_url}/d/#{id}"
    end

    def token_path(id)
      "#{xtt_url}/t/#{id}"
    end

    def device_id(device)
      request_put_text(device_path(nil), device)
    end

    def tokens(device, type, page)
      response = request_get_json("#{device_path(device)}/#{type}/#{page}")
      response['tokenList']['tokens']
    end

    def order_detail(order_token)
      request_get_json(token_path(order_token))
    end

    def xtt_tokens(device, page:1)
      tokens(device, 'tokens', page)
    end

    def driver_tokens(device, page:1)
      tokens(device, 'driverOrders', page)
    end

    def shipper_token(device)
      xtt_tokens(device)[1]
    end

    def shipper_order_detail(device)
      shipper = shipper_token(device)
      order_detail(shipper)
    end

    def consignee_token(device)
      xtt_tokens(device)[0]
    end

    def consignee_order_detail(device)
      consignee = consignee_token(device)
      order_detail(consignee)
    end

    def update_milestone(milestone_id, token, data_set)
      @milestone_detail = milestone_details(data_set)
      request_post_json(
        "#{token_path(token)}/milestones/MILESTONE_#{milestone_id}",
        { milestoneDetails: @milestone_detail }.to_json)
    end

    def driver_update_milestone(milestone_id, token, data_set)
      data_set[:id] ||= "MILESTONE_#{milestone_id}"
      data_set[:actual] ||= request_time
      @milestone_detail = data_set
      request_post_json(
        "#{token_path(token)}/milestoneupdate",
        { milestoneDetails: @milestone_detail }.to_json)
    end

    def request_time
      Time.new.strftime('%Y-%m-%dT%H:%M:%S%:z')
    end

    def milestone_details(data_set)
      data_set ||= {}
      data_set[:actual] ||= request_time
      data_set[:comments] ||=
        "update milestone at #{data_set[:actual]}"
      data_set[:stars] ||= 3
      data_set
    end

    def return_error(e)
      e.respond_to?('http_code') ? e.http_code : e
    end

    def sms_code
      print '  -> enter sms code: '
      std_code = $stdin.gets.chomp
      puts '  -> got it.'
      std_code
    end

    def mail_code
      start_time = Time.new
      print '  -> checking inbox...'
      mail = activation_mail(start_time, symbol_hash(data['mail']['mail_set']))
      print "done.\n"
      mail.body.raw_source.scan(%r{<code>.*<\/code>})[0].split(/\W/)[2]
    end

    def add_truck_node(from_hash:nil)
      truck_info = YAML.load_file('init_data.yml')['sr']['truck']
      request = add_node_to_xml(
        { toTruck: { value: nil, before: 'cargoDetails' } },
        from_hash: from_hash)
      add_child_to_xml(
        { driver: { value: truck_info['driver_name'], parent: 'toTruck' },
          truckPlate: { value: truck_info['truck_plate'], parent: 'toTruck' },
          phone: { value: truck_info['driver_mobile'], parent: 'toTruck' } },
        from_hash: request)
    end
  end
end
