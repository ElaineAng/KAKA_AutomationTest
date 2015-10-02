require 'yaml'
require_relative '_case'
require_relative '_case_api'

# Import orders by API
class ApiImportOrder < Otms::Case
  include Otms::CaseApi

  def scenario_0_single_inbox_order
    @original = "#{$cur_path}/bin/data/import_order.xml"
    response = api.import_order(file: @original)
    results << assert_equal(response.at_css('importStatus').text, 'INBOX')
    add_imported_request_to_file
  end

  def scenario_1_cannot_import_single_inbox_order
    import_file
  end

  def scenario_2_single_draft_order
    @temp_draft = 'bin/data/import_draft.xml'
    api.update_node({ companyName: '' },
                    from_file: @original,
                    to_file: @temp_draft)
    response = api.import_order(file: @temp_draft)
    results << assert_equal(response.at_css('importStatus').text, 'DRAFT')
    add_imported_request_to_file
  end

  def scenario_3_cannot_import_single_draft_order
    import_file
  end

  def scenario_4_multiple_inbox_order
    @temp_orders = 'bin/data/import_orders.xml'
    results[4] = []
    api.dup_order_to_file(from_file: @original, to_file: @temp_orders)
    response = api.import_order(file: @temp_orders)
    assert_noko_response(response, { importStatus: 'INBOX' }, result: 4)
    add_imported_request_to_file
  end

  def scenario_5_cannot_import_multiple_inbox_order
    import_file
  end

  def scenario_6_multiple_draft_order
    @temp_drafts = 'bin/data/import_drafts.xml'
    results[6] = []
    api.dup_order_to_file(from_file: @temp_draft, to_file: @temp_drafts)
    response = api.import_order(file: @temp_drafts)
    response.css('importStatus').each do |s|
      results[6] << assert_equal(s.text, 'DRAFT')
    end
    add_imported_request_to_file
  end

  def scenario_7_cannot_import_multiple_draft_order
    import_file
  end

  def scenario_8_can_update_single_inbox_order
    @temp_update = 'bin/data/import_order_update.xml'
    api.add_node({ allowUpdate: { value: 'true', sibling: 'erpNumber' } },
                 from_file: @original,
                 to_file: @temp_update)
    response = api.import_order(file: @temp_update)
    results << assert_equal(response.at_css('importStatus').text, 'INBOX')
    add_imported_request_to_file
  end

  def scenario_9_can_update_single_inbox_order
    import_file(file: @imported_file, status: 'INBOX')
    add_imported_request_to_file
  end

  def scenario_10_cannot_update_single_inbox_order
    api.update_node({ allowUpdate: 'false' },
                    from_file: @imported_file,
                    to_file: @imported_file)
    import_file(file: @imported_file, status: 'NOT IMPORTED')
  end

  def scenario_11_can_release_inbox_order
    request = api.add_node_to_xml(
      { autoProcessMode: { value: 2, before: 'cargoDetails' } },
      from_hash: future_order_request)
    response = api.import_order(request: request)
    results << assert_equal(response.at_css('importStatus').text, 'RELEASED')
  end

  def scenario_12_can_dispatch_inbox_order
    request = api.add_node_to_xml(
      { autoProcessMode: { value: 3, before: 'cargoDetails' } },
      from_hash: future_order_request)
    response = api.import_order(request: request)
    results << assert_equal(response.at_css('importStatus').text, 'DISPATCHED')
  end

  def scenario_13_can_dispatch_order_to_truck
    request = api.add_node_to_xml(
      { autoProcessMode: { value: 4, before: 'cargoDetails' } },
      from_hash: future_order_request)
    request = api.add_truck_node(from_hash: request)
    response = api.import_order(request: request)
    results << assert_equal(response.at_css('importStatus').text, 'DISPATCHED')
  end

  def report
    @report_step = 'Import orders by API'
  end
end

# ApiImportOrder.new.process

# def can_update_multiple_inbox_order
# end

# def cannot_update_multiple_inbox_order
# end

# def can_update_part_of_multiple_inbox_order
# end

# def can_update_single_draft_order
# end

# def cannot_update_single_draft_order
# end

# def can_update_multiple_draft_order
# end

# def cannot_update_multiple_draft_order
# end

# def can_update_part_of_multiple_draft_order
# end

# def can_update_inbox_to_draft
# end

# def can_update_draft_to_inbox
# end
