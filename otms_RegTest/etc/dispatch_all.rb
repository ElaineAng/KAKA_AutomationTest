require_relative '_required'
require 'bin/_case'

# dispatch all orders
class DispatchAll < Otms::Case
  def scenario_0_dispatch_all
    Watir.default_timeout = 180
    switch_user('sr')
    dc.navigate
    dc.navigate_sub_tab('under_allocation', index: 1)
    dc.batch_confirm_assigned
    results << 'Pass'
  end

  def report
    @report_step = 'dispatch all orders'
  end
end

DispatchAll.new.process
