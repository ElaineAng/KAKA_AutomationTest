require_relative '../load_path'
require_relative '_base_private'
require 'lib/common/load_data'
require 'lib/common/report'

module Otms
  # Super class for business class
  class Base
    attr_accessor :sys, :data, :check
    include LoadData
    include Report
    include BasePrivate

    def initialize(parent, report:nil)
      load_objects(parent)
      initialize_template(report)
      @sys = parent
      @data = initialize_data(data_file) if File.exist?(data_file)
      @check = initialize_data(check_file) if File.exist?(check_file)
    end

    def navigate_url(address)
      address ||= otms_url
      @address = address
      sys.goto address
    end

    def load_objects(parent)
      load_object(common_file, parent: parent)
      load_object(popup_file, parent: popup_content)
      load_object(parent: parent)
    end

    def wait_until(condition, present:nil, timeout:nil)
      present ||= 15
      timeout ||= 3
      Watir::Wait.until(present) { condition }
      sleep timeout
    end

    def wait_loading(timeout:nil)
      timeout ||= 3
      sleep timeout
      popup_waiting.wait_while_present
    end

    def wait_while_message
      load_object(common_file, parent: @sys)
      popup_message.click if popup_message.exist?
    rescue
      popup_message.wait_while_present
    end

    def navigate
      load_filters(filter_file, parent: @sys, index: 0)
      tab.when_present.click
      wait_loading
    end

    def navigate_sub_tab(sub_tab, index:nil)
      load_filters(filter_file, parent: @sys, index: index)
      send("sub_tab_#{sub_tab}").when_present.click
      wait_loading
    end

    def search(text, text_object:nil, timeout:nil)
      timeout ||= 1.5
      text_object.wait_until_present
      input_search('', text_object, timeout) unless text_object.value.empty?
      input_search(text, text_object, timeout)
    end

    def select_popup(text, parent:nil)
      sleep 1.5
      parent ||= popup_content
      regexp = text.is_a?(Array) ? Regexp.union(text) : /#{text}/
      popup_text = parent.span(text: regexp)
      parent.wait_until_present
      try_until(popup_text, parent)
      popup_text.click
      parent.wait_while_present
    end

    def select_every_row(select_first:true)
      table.rows.size.times do |r|
        selected_row = select_first ? 0 : r
        table.[](selected_row).click
        yield
      end
    end

    def load_headers
      load_object(hash: { 'headers' => { 'node' => 'table' } },
                  parent: table_header)
    end

    def select_all_records(table_object = nil, col:0)
      table_object ||= table
      checkbox_1 = table_object.[](0).[](col).checkbox
      load_headers
      select_all_img = headers.[](0).[](col).img
      select_all_img.when_present.click
      wait_loading
      select_all_img.click unless checkbox_1.set?
    end

    %w(add edit clone save save_and_close delete exit).each do |action|
      define_method("#{action}_record") do |timeout:nil|
        send("button_#{action}_record").click
        wait_loading(timeout: timeout)
      end
    end

    def adding_record
      add_record
      yield
      save_and_close_record
    end

    def loading_popup(popup_object = nil)
      popup_object ||= popup_content
      popup_object.wait_until_present
      load_object(popup_file, parent: popup_object)
      yield
      popup_object.wait_while_present
    end

    def loaded_message
      return unless popup_message.exist?
      popup_message.click
      popup_message.wait_while_present
    end
  end
end
