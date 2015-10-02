module Otms
  # public methods for Otms::OrderCenter
  module OrderCenterPublic
    def search_by_remark(text, timeout:nil)
      load_filters(filter_file, parent: @sys, index: 0)
      search(text, text_object: oc_inbox_remark, timeout: timeout)
    end

    def assert_order_preview(data_set)
      result = []
      table.rows.size.times do |row|
        open_order_preview(row)
        data_set.each_with_index do |(key, value), index|
          result[index] =
            assert_equal(send("preview_#{key}").text, value.to_s, title: key)
        end
        close_order_preview
      end
      assert_array(result)
    end
  end
end
