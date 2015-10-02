require_relative '_case'

# add new order
class OcNew < Otms::Case
  def scenario_0_add_new_order_in_sr
    switch_user('sr')
    results << add_new_order('new', 'draft')
  end

  def scenario_1_add_new_order_in_sp
    switch_user('sp')
    results << add_new_order('sp_new', 'sp_draft')
  end

  def report
    @report_step = 'add new order'
  end

  def add_new_order(*data_nodes)
    result = []
    oc.navigate
    data_nodes.each do |node|
      oc.navigate_sub_tab('draft_box') if node.include?('draft')
      order_data = oc.data[node]
      oc.add_new_order(data_set: order_data)
      result << assert_new_order(order_data)
    end
    result
  end

  def assert_new_order(expected)
    oc.search_by_remark(expected['remark'])
    expected.delete('suggested_tariff')
    expected['ship_from'].gsub!(%r{\s*\/.*}, '')
    expected['ship_to'].gsub!(%r{\s*\/.*}, '')
    oc.assert_order_preview(expected)
  end
end

OcNew.new.process
