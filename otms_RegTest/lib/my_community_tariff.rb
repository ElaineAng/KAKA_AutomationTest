module Otms
  # public methods for tariff business
  module MyCommunityTariff
    def load_tariff_object
      tariff_object = initialize_data('bin/object/tariff.yml')
      load_object(
        hash: decode_hash('sub_tab' => tariff_object['tariff_sub_tab']),
        parent: @sys)
      tariff_object.reject { |k, _v| k == 'tariff_sub_tab' }.each do |_k, v|
        load_object(hash: decode_hash('tariff' => v), parent: main_panel)
      end
    end

    def input_tariff_basic_data(data_set)
      basic_data = data_set.reject { |k, _v| k == :kpi || k == :lanes }
                   .merge(parent: popup_content)
      if basic_data[:type]
        input_new_master_data(
          'tariff', basic_data.select { |k, _v| k == :type || k == :parent })
      end
      input_new_master_data('tariff', basic_data.reject { |k, _v| k == :type })
    end

    def input_lanes(lanses = [])
      lanses.each { |lane| input_lane(lane) }
    end

    def input_kpi(kpi)
      return unless kpi
      navigate_sub_tab('sla_or_kpi')
      input_new_master_data('tariff_kpi', kpi)
    end

    def input_lane(lane = {})
      %i(origin destination).each { |v| send("input_#{v}", lane[v]) }
      input_points(range_points(lane[:rates].keys))
      input_rates(lane[:rates].values)
      input_lead_time(lane[:lead_time])
    end

    def range_points(ranges)
      ranges.reject { |v| v == :min || v == :any }
        .join.split('_').select { |v| v.to_i > 0 }.uniq
    end

    def input_points(points)
      return unless tariff_destination_table.rows.size < 2
      tariff_add_range.click
      loading_popup do
        points.each do |range|
          tariff_range_point.set(range)
          tariff_range_add_point.click
        end
        tariff_range_close.click
      end
    end

    def input_rates(rates)
      rates.each_with_index do |rate, index|
        tariff_destination_table.[](0).[](index + 3).text_field.send_keys(
          :backspace, :backspace, :backspace, :backspace, rate)
      end
    end

    def input_lead_time(lead_time)
      return unless lead_time
      tariff_destination_table.[](0).[](-1).text_field.send_keys(
        :backspace, lead_time)
    end

    def input_origin(value)
      input_table_row(:origin, value) do
        tariff_origin_table.[](-1).click
      end
    end

    def input_destination(value)
      input_table_row(:destination, value) do
        tariff_destination_table.[](0).click
      end
    end

    def input_table_row(table_type, value)
      sleep 3
      table_rows = send("tariff_#{table_type}_table").rows
      expected_row(table_rows, value) do
        send("tariff_#{table_type}").set(value)
        select_popup("#{value}.*", parent: popup_content)
        send("tariff_add_#{table_type}").click
        sleep 3
        yield
      end
    end

    def expected_row(table_rows, value)
      rows = table_rows.select { |r| r.[](2).text =~ /#{value}.*/ }
      if table_rows.size < 1 || rows.empty?
        yield
      else
        rows
      end
    end
  end
end
