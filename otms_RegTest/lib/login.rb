require_relative '_base'
require 'watir-webdriver'

module Otms
  # Log in & out
  class Login < Base
    attr_reader :browser, :role

    def initialize(address:nil, browser:nil)
      initialize_browser(browser)
      navigate_url(address)
      @data = initialize_data("#{$cur_path}/key.yml") if File.exist?("#{$cur_path}/key.yml")
    end

    def initialize_browser(browser)
      browser ||= config.browser
      @sys = Watir::Browser.new browser
      sys.window.resize_to 3000, 3000
      sys.window.maximize
    end

    def navigate_url(address)
      super
      load_object
    end

    def user_on(role:'sr', data_set:nil)
      @role = role
      data_set ||= @data[role]['account']

      home_logo.wait_until_present
      home_username.set data_set['username']
      home_password.send_keys data_set['password']
      try_login
      return if otms_logout.exist?
      update_lang_and_login_again(role, data_set)
    end

    def update_lang_and_login_again(role, data_set)
      update_lang
      user_on(role: role, data_set: data_set)
    end

    def update_lang
      try_other_object do
        otms_my_preferences.click
        otms_user_settings.when_present.click
      end
      otms_interface_language.when_present.parent.radio.set
      try_other_object { otms_logout.click }
    end

    def change_lang
      otms_my_preferences.click
      otms_user_settings.when_present.click
      try_other_object { otms_interface_language.when_present.parent.radio.set }
    end

    def user_off
      wait_while_message
      otms_logout.when_present.click
      home_logo.wait_until_present(5)
    rescue
      navigate_url(@address)
    end

    def close
      sys.close
      @sys = nil
    end

    private

    def try_other_object
      load_object(lang: other_lang)
      yield
      load_object
    end

    def try_click_login
      if home_login.exist?
        home_login.click
      else
        try_other_object { home_login.click }
      end
    end

    def try_login
      loop do
        begin
          try_click_login
          otms_logo.wait_until_present
          break
        rescue StandardError
          next
        end
      end
    end
  end
end
