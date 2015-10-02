require_relative '_required'
require 'lib/api'

Otms::Api.new.send("request_#{ARGV[1]}_#{ARGV[3]}", ARGV[0], File.read(ARGV[2]))
