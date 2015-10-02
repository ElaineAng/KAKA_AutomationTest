require_relative '_required'
require 'bin/_case'

# release all orders
class ReleaseAll < Otms::Case
  def scenario_0_release_all
    switch_user('sr')
    oc.navigate
    ARGV[0].to_i.times do |n|
      oc.release_orders
      puts "  -> released #{(n + 1) * 50} orders"
    end
    results << 'Pass'
  end

  def report
    @report_step = 'release all orders'
  end
end

ReleaseAll.new.process
