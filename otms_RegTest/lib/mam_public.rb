module Otms
  # public methods for Otms::Mam
  module MamPublic
    def write_config(file)
      file.puts '---'
      file.puts "env: #{config.env}"
    end

    def write_key_file(file, data_set)
      file = write_out_key_data(file, data_set)
      file.close
    end

    def write_out_key_data(file, data_set)
      data_set.each do |key, value|
        file.puts "#{key}:"
        value.each do |k, v|
          file.puts "  #{k}:"
          file.puts "    username: #{v[:username]}"
          file.puts "    password: #{v[:password]}"
        end
      end
      file
    end

    def key_data_hash(role, username, password, api_username, api_password)
      { role =>
        { account: { username: username,
                     password: password },
          api: { username: api_username,
                 password: api_password } } }
    end

    private

    def super_user(data_set)
      %w(username password).each { |v| data_set[v.to_sym] = data['admin'][v] }
      data_set
    end

    def revoke_and_grant_api_key
      mam_tab_api_access.when_present.click
      wait_loading
      mam_button_revoke_api.when_present.click
      wait_loading
      mam_button_grant_api.click
      wait_loading
    end

    def api_key_at_labels(keys)
      labels.each do |div|
        keys = login_key(keys, div.text)
        break if keys[-1].is_a?(Hash) && keys[-1].key?(:password)
      end
      keys.delete_at(0)
      keys
    end

    def login_key(keys, text)
      if keys[0] == 'Import login:'
        keys << { login: text }
        keys[0] = text
        keys
      elsif keys[0] == 'Import password:'
        keys[-1][:password] = text
      else
        keys[0] = text
      end
      keys
    end

    def add_custom_field(index, checks, labels)
      custom_field =
        popup_content.div(class: 'v-horizontallayout', index: index)
      load_object('bin/object/_custom_field.yml', parent: custom_field)
      enable_check_options(checks)
      add_labels(labels)
    end

    def enable_check_options(checks)
      checkbox_enabled.set
      wait_loading
      checks.each { |option| send("checkbox_#{option}").set }
    end

    def add_labels(labels)
      labels.reject { |k, _v| k.to_s == 'options' } .each do |option, value|
        send("label_#{option}").set(value)
      end
      return unless enum_options.exist?
      enum_options.click
      add_enum_options(labels[:options])
    end

    def add_enum_options(options)
      loading_popup(new_popup) do
        options.each { |option| add_enum_option(option) }
        enum_option_button_save.click
        wait_loading
        new_popup_close.click if new_popup_close.exist?
      end
    end

    def add_enum_option(option)
      load_object('bin/object/_custom_field.yml', parent: new_popup)
      enum_option_button_add.when_present.click
      wait_loading
      option.each { |k, v| send("enum_option_name_#{k}").set(v) }
    end

    def input_custom_fields(data_set)
      data_set.each do |type, field|
        send("mam_tab_#{type}_fields").when_present.click
        wait_loading
        field.each do |f|
          add_custom_field(
            custom_field_index(f[:index], type), f[:checks], f[:labels])
        end
      end
    end

    def custom_field_index(index, type)
      index += 10 if type.to_s == 'numeric'
      index += 20 if type.to_s == 'enums'
      index
    end
  end
end
