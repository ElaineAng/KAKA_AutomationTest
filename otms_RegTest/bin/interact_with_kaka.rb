require_relative 'KAKA_Methods'
require 'nokogiri'
require 'yaml'

include Otms::KAKAMethods
order = YAML.load(File.open($cur_path+'/../config.yml'))['import_order']

def ref(order)
  order_details=Nokogiri::XML(File.read(order))
  ref_num = order_details.xpath('//clientReferenceNumber').text.split('-')[1]
  return ref_num
end

while cmd = $stdin.gets

  cmd.chop!
  if cmd == 'exit'
    break
  else
    puts eval(cmd)
    puts '[end]'
    $stdout.flush
  end
end

