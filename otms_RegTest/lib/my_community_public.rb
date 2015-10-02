module Otms
  # public methods for Otms::MyCommunity
  module MyCommunityPublic
    def search_by_tariff_name(tariff_name, timeout:nil)
      load_filters(filter_file, parent: sys)
      search(tariff_name, text_object: mc_tariff_name, timeout: timeout)
    end

    def search_by_truck_plate(truck_plate, timeout:nil)
      load_filters(filter_file, parent: sys)
      search(
        truck_plate, text_object: mc_my_trucks_truck_plate, timeout: timeout)
    end

    def input_new_master_data(type, data_set)
      data_set[:parent] ||= new_popup
      data_set.reject { |k, _v| k == :parent } .each do |k, v|
        new_input_object = send("#{type}_#{k}")
        if new_input_object.is_a?(Watir::Div)
          click_count = k == 'capacity' ? 2 : 1
          click_count.times { new_input_object.click }
          select_popup(v, parent: data_set[:parent])
        elsif new_input_object.is_a?(Watir::TextField)
          new_input_object.set(v)
        end
      end
    end
  end
end
