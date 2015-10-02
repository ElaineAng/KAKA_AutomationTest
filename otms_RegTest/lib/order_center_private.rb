module Otms
  # private methods for Otms::OrderCenter
  module OrderCenterPrivate
    private

    def save_order(quantity, data_set)
      quantity = quantity.to_i
      input_order(data_set.reject { |k, _v| k == 'remark' })
      (quantity - 1).times { clone_record(timeout: 0.5) }
      switch_to_first_tab
      quantity.times { |t| input_remark_and_save(data_set['remark'], t) }
      wait_loading
    end

    def switch_to_first_tab
      loop do
        begin
          edit_area_tabs.[](0).[](0).div.click
          edit_area_remark.wait_until_present(5)
          break if edit_area_remark.exist? && edit_area_remark.visible?
        rescue StandError
          next
        end
      end
    end

    def input_order(data_set)
      input_div_fields(data_set)
      input_location(data_set['location']) if data_set['location']
      if data_set['product_qty']
        wait_until(sys.table.rows.size > 0, timeout: 0.5)
        input_product_quantity(data_set['product_qty'])
      end
      input_ship_info_text_fields(data_set)
      input_text_fields(data_set)
    end

    def input_remark_and_save(remark, seq)
      seq = seq.to_i > 0 ? "_#{seq}" : nil
      remark = "#{remark}#{seq}"
      edit_area_remark.set(remark)
      save_and_close_record(timeout: 0.5)
      button_yes.click if button_yes.exist?
    end

    def required_div_fields
      %w(client
         ship_from
         ship_to)
    end

    def optional_div_fields
      %w(product)
    end

    def required_text_fields
      %w(total_weight
         total_volume
         pickup_date
         lead_time
         delivery_date
         weight
         volume)
    end

    def required_ship_info
      %w(name
         internal_id
         address
         contact
         phone
         mobile)
    end

    def optional_text_fields
      %w(remark
         erp
         ship_from_remark
         ship_to_remark
         transport_remark
         product_value
         pickup_remark
         delivery_remark)
    end

    def input_div_fields(data_set)
      (required_div_fields + optional_div_fields).each do |div|
        if data_set[div]
          sys.div(class: 'v-label v-label-cursor-pointer cursor-pointer',
                  text: data_set[div]).when_present.click
        end
      end
    end

    def input_text_field(name, value)
      return unless value
      text_object = send("edit_area_#{name}")
      text_object.set(value) unless text_object.read_only?
    end

    def input_ship_info_text_fields(data_set)
      ship_fields = []
      %w(from to).each do |type|
        ship_fields += required_ship_info.map { |v| "ship_#{type}_#{v}" }
      end
      ship_fields.each do |ship_field|
        input_text_field(ship_field, data_set[ship_field])
        select_popup(data_set[ship_field]) if ship_field =~ /.*internal_id/
      end
    end

    def input_text_fields(data_set)
      (required_text_fields + optional_text_fields).each do |field|
        input_text_field(field, data_set[field])
      end
    end

    def input_product_quantity(qty)
      product_lines = table.rows.length
      table.[](product_lines - 1).[](5).text_field.set(qty)
      edit_area_product_cal.click
    end

    def input_location(location)
      edit_area_location.click
      select_popup(location)
    end

    def open_order_preview(row)
      table.[](row).[](2).span.click
      popup_content.wait_until_present
      load_preview_object
      preview_order_no.wait_until_present
    end

    def close_order_preview
      popup_content_close.click
      popup_content.wait_while_present
    end

    def select_release_option(option)
      wait_loading
      release_option = send("release_option_#{option}")
      release_option.click if release_option.exist?
      wait_loading
    end
  end
end
