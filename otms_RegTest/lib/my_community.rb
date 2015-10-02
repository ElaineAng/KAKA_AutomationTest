require_relative '_base'
require_relative 'my_community_public'
require_relative 'my_community_tariff'
require_relative 'common/output'

module Otms
  # My Community business
  class MyCommunity < Base
    include MyCommunityPublic
    include MyCommunityTariff
    include Output

    def add_offline_vendor(data_set = {})
      adding_record do
        load_object(
          hash: decode_hash(
            'my_vendors' => initialize_data(class_file)['my_vendors']),
          parent: main_view)
        input_role(data_set[:role]) if data_set[:role]
        input_new_master_data(
          'my_vendors', data_set.reject { |k, _v| k == :role })
      end
      exit_record
    end

    def input_role(role)
      my_network_role.click
      select_popup(role)
      my_network_role.wait_while_present
    end

    alias_method :add_offline_client, :add_offline_vendor

    def add_new_tariff(data_set = {})
      adding_record do
        load_tariff_object
        input_tariff_basic_data(data_set)
        input_lanes(data_set[:lanes])
        input_kpi(data_set[:kpi])
      end
      loaded_message
    end

    def exit_tariff
      return unless popup_content.exist?
      loading_popup { popup_content_close.click }
      exit_record
    end

    def delete_tariff
      select_every_row do
        wait_loading
        delete_record
        loading_popup { popup_confirm.click }
      end
    end

    def send_tariff
      select_every_row do
        wait_loading
        my_tariffs_negotiation.click
        my_tariffs_send_tariff.when_present.click
      end
    end

    def accept_tariff
      select_every_row do
        wait_loading
        my_tariffs_negotiation.click
        my_tariffs_accept.when_present.click
      end
    end

    def add_new_truck(data_set = {})
      add_record
      loading_popup do
        input_new_master_data('new_truck', data_set)
        new_truck_save.click
        wait_loading
        new_truck_cancel.click if new_truck_cancel.exist?
      end
    end

    def invite_truck
      select_every_row(select_first: false) do
        my_trucks_invite.click
        wait_loading
      end
    end

    def add_new_product(data_set = {})
      adding_record do
        loading_popup do
          input_new_master_data('new_product', data_set)
          first_button.click
          wait_loading
          wait_while_message
        end
      end
    end

    def import_master_data(data_set = {})
      my_master_data_import.click
      popup_content.wait_until_present
      my_master_data_xls_file.set(File.absolute_path(data_set[:file]))
      popup_content_close.when_present.click
      popup_content.wait_while_present
    end

    def add_new_location(data_set = {})
      adding_record do
        my_locations_name.set(data_set[:location_name])
        if data_set[:third_party_name]
          my_locations_third_party_operator.click
          sleep 1.5
          my_locations_third_party_name.set(data_set[:third_party_name])
        end
        my_locations_archive.click if data_set[:archive]
      end
    end

    def invite_by_email(mail, relationship)
      my_invitations_invite.click
      my_invitations_email.when_present.set(mail)
      my_invitations_invitation_text.set('sent by ruby robot')
      my_invitations_select_relationship.click
      select_popup(relationship)
      my_invitations_send_invite.click
      wait_loading
    end

    def accept_invitation(invitation_code)
      my_invitations_invitation_code.set(invitation_code)
      my_invitations_confirm_code.click
      table.[](0).when_present.click
      my_invitations_accept.when_present.click
      wait_loading
    end
  end
end
