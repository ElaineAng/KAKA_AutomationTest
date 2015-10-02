require_relative '_base'
require_relative 'mam_public'

module Otms
  # Super user MAM
  class Mam < Base
    include MamPublic

    def entry(data_set = {})
      data_set = super_user(data_set)
      home_username.when_present.set(data_set[:username])
      home_password.set(data_set[:password])
      home_login.click
      sub_tab_otms_companies.wait_until_present
    end

    def logout
      mam_logout.click
      mam_logout.wait_while_present
    end

    def exit
      logout
      sys.close
      @sys = nil
    end

    def search_by_code(text, timeout:nil)
      load_filters(filter_file, parent: @sys, index: 0)
      search(text, text_object: mam_otms_companies_code, timeout: timeout)
    end

    def entry_setting
      table.[](0).click
      loading_popup do
        yield
        popup_content_close.click
      end
    end

    def new_api_keys
      keys = []
      entry_setting do
        revoke_and_grant_api_key
        keys = api_key_at_labels(keys)
      end
      keys
    end

    def write_out_key_file(file_name = 'key.yml', data_set:nil)
      if File.exist?(file_name) &&
         !initialize_data(file_name).key?(data_set['role'])
        file = File.open(file_name, 'a:UTF-8')
      else
        file = File.open(file_name, 'w+:UTF-8')
        write_config(file)
      end
      write_key_file(file, data_set)
      initialize_data(file_name)
    end

    def configure_custom_field_rigths(option)
      options = [['No right to custom fields', '没有权限使用自定义字段'],
                 ['Configured by Management System', '后台配置'],
                 ['Configured by user', '用户配置']]
      mam_filter_custom_field.click
      select_popup(options[option.to_i], parent: new_popup)
      mam_button_set_custom_field.click
      sys.refresh
      wait_loading
    end

    def add_custom_fields(data_set)
      entry_setting do
        configure_custom_field_rigths(1)
        mam_tab_custom_field.when_present.click
        input_custom_fields(data_set)
        load_object(popup_file, parent: popup_content)
        mam_button_save.click
        wait_loading
      end
    end

    def configure_access(access)
      entry_setting do
        send("access_#{access}").click
        wait_loading
      end
    end
  end
end
