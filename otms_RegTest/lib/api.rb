require_relative '_base'
require_relative 'api_private'
require_relative 'api_public'

module Otms
  # API business
  class Api < Base
    include ApiPublic
    include ApiPrivate

    def initialize(report:nil)
      initialize_template(report)
      @data = initialize_data(data_file)
    end

    def import_order(data_set = {})
      data_set[:root] = 'orderImportRequest'
      data_set[:request] ||= decode_file(identified(data_set))
      request_put_xml("#{ws_url}/orderImport", data_set[:request])
    end

    def import_orders(order_no, data_set = {})
      data_set[:response] = []
      order_no.to_i.times do |n|
        data_set[:response] << import_order(data_set.merge(seq: n))
        puts "  -> #{n + 1} orders imported."
      end
      data_set[:response]
    end

    def import_billing(data_set = {})
      data_set[:root] = 'externalBillingImportRequest'
      data_set[:request] ||= decode_file(identified(data_set))
      data_set[:private_data] ||= {}
      request_put_xml(
        "#{ws_url}/externalBilling",
        default_billing_data(data_set[:request], data_set[:private_data]))
    end

    def import_billings(billing_no, data_set = {})
      data_set[:response] = []
      billing_no.to_i.times do
        data_set[:response] << import_billing(data_set)
        puts "  -> #{n + 1} billings imported."
      end
      data_set[:response]
    end

    def import_ship_point(data_set = {})
      data_set[:root] = 'shipPointImportRequest'
      data_set[:request] ||= decode_file(identified(data_set))
      data_set =
        data_set.key?(:file) ? update_ship_point_type(data_set) : data_set
      request_put_xml("#{ws_url}/shipPointImport", data_set[:request])
    end

    def remove_ship_point(data_set = {})
      data_set[:root] = 'shipPointRemoveRequest'
      data_set[:request] ||= decode_file(identified(data_set))
      data_set = if data_set.key?(:file)
                   update_nodes(ship_point_nodes, data_set)
                 else
                   data_set
                 end
      request_delete_xml("#{ws_url}/shipPointImport", data_set[:request])
    end

    def activate(device, data_set = {})
      request_post_json(device_path(device), { device: data_set }.to_json)
    end

    def pickup(device, data_set = {})
      data_set[:token] ||= shipper_token(device)
      update_milestone(
        4, data_set[:token], data_set.reject { |k, _v| k == :token })
    rescue StandardError => e
      return_error(e)
    end

    def delivery(device, data_set = {})
      data_set[:token] ||= consignee_token(device)
      update_milestone(
        5, data_set[:token], data_set.reject { |k, _v| k == :token })
    rescue StandardError => e
      return_error(e)
    end

    def upload_epod(device, data_set = {})
      data_set[:token] ||= consignee_token(device)
      request_put_file("#{token_path(data_set[:token])}/epod", data_set[:file])
    rescue StandardError => e
      return_error(e)
    end

    def driver_pickup(device, data_set = {})
      data_set[:token] ||= driver_tokens(device)[0]
      driver_update_milestone(
        4, data_set[:token], data_set.reject { |k, _v| k == :token })
    rescue StandardError => e
      return_error(e)
    end

    def driver_delivery(device, data_set = {})
      data_set[:token] ||= driver_tokens(device)[0]
      driver_update_milestone(
        5, data_set[:token], data_set.reject { |k, _v| k == :token })
    rescue StandardError => e
      return_error(e)
    end
  end
end
