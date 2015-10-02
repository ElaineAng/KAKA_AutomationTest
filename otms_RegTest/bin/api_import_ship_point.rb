require_relative '_case'
require_relative '_case_api'

# Import ship points by API
class ApiImportShipPoint < Otms::Case
  include Otms::CaseApi

  def scenario_0_add_ship_from
    response = api.import_ship_point(file: 'bin/data/import_ship_point.xml')
    results << assert_equal(response.at_css('importStatus').text, 'ADDED')
    add_imported_request_to_file
  end

  def update_client_reference_number(xml)
    xml.at_css('clientReferenceNumber').content =
      api.noko_xml_file(@imported_file).at_css('clientReferenceNumber').text
    File.delete(@imported_file)
    xml
  end

  def updated_remove_file(xml, type)
    xml.at_css('type').content = type
    api.api_key.each do |k, v|
      xml.at_css('shipPointRemoveRequest')[k.to_s] = v
    end
    update_client_reference_number(xml).to_xml
  end

  def create_remove_file(type)
    @removed_file = 'bin/data/removed.xml'
    to_xml = api.noko_xml_file('bin/data/remove_ship_point.xml')
    api.write_xml_to_file(
      @removed_file, xml: updated_remove_file(to_xml, type))
  end

  def scenario_1_update_ship_from
    import_file(type: 'import_ship_point', status: 'UPDATED')
    add_imported_request_to_file
    create_remove_file(0)
  end

  def scenario_2_delete_ship_from
    import_file(
      type: 'remove_ship_point', file: @removed_file, status: 'REMOVED')
  end

  def scenario_3_add_ship_to
    response = api.import_ship_point(
      file: 'bin/data/import_ship_point.xml', type: 1)
    results << assert_equal(response.at_css('importStatus').text, 'ADDED')
    add_imported_request_to_file
  end

  def scenario_4_update_ship_to
    response = api.import_ship_point(
      request: api.decode_str(str: File.read(@imported_file)), type: 1)
    results << assert_equal(response.at_css('importStatus').text, 'UPDATED')
    create_remove_file(1)
  end

  def scenario_5_delete_ship_to
    scenario_2_delete_ship_from
  end

  def report
    @report_step = 'Import ship points by API'
  end
end

ApiImportShipPoint.new.process
