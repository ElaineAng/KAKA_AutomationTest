module Otms
  # private methods for Otms::DispatchCenter
  module DispatchCenterPrivate
    private

    def confirm_tariff(index)
      select_tariff_frame.img(src: /.*ok.png/, index: index).when_present.click
    end

    def select_expected_tariff(tariff_name)
      select_tariff_frame.wait_until_present
      sleep 3
      tariffs = select_tariff_frame.text.split(/\n/)
      return unless tariffs.include?(tariff_name)
      confirm_tariff(tariffs.index(tariff_name) / 6 - 1)
      select_tariff_frame.wait_while_present
    end

    def wait_truck_table
      load_object(hash: { 'truck_table' => { 'node' => 'table',
                                             'class' => 'v-table-table' } },
                  parent: popup_content)
      truck_table.wait_until_present
    end

    def select_truck_by_text(truck_row, driver, plate)
      return 'not matched' unless truck_row.[](1).div.text == driver &&
                                  truck_row.[](2).div.text == plate
      truck_row.[](0).span.click
    end

    def select_expected_truck(driver, plate)
      wait_truck_table
      truck_table.rows.size.times do |row|
        truck_row = truck_table.[](row)
        next if select_truck_by_text(
          truck_row, driver, plate) == 'not matched'
        popup_content.wait_while_present
        break
      end
    end

    def select_first_truck
      wait_truck_table
      truck_table.[](0).[](0).span.click
      popup_content.wait_while_present
    end
  end
end
