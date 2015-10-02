require_relative 'load_path'
require 'bin/_case'
require 'bin/_case_api'
require 'mail'

# Demo business
class Demo < Otms::Case
  include Otms::CaseApi

  def scenario_0_import_new_order_by_import_api
    ARGV[0] ||= 50
    @orders = ARGV[0]
    results[0] = []
    response = api.import_orders(@orders, file: "#{$cur_path}/bin/data/import_order.xml")
    response.each do |r|
      results[0] << assert_equal(r.at_css('importStatus').text, 'INBOX')
    end
  end

  def scenario_1_assign_truck_in_dispatch_center
    Watir.default_timeout = 120
    dispatch_offline_order(new_order: false, truck_data: '', batch: true)
    results << 'Pass'
  end

  def scenario_2_update_milestone_in_track_and_trace
    batch_pickup
    batch_delivery
    results << 'Pass'
  end

  def report
    @report_step = 'oTMS business demo'
    @report_file = "#{report_path}/demo.html"
  end
end

demo = -> { Demo.new.process }

if ARGV[-1] && ARGV[-1].include?('@')
  trap('SIGINT') { throw :ctrl_c }
  catch :ctrl_c do
    loop do
      begin
        require 'headless'
        Headless.ly { demo.call }
        break
      rescue StandardError => e
        puts e, e.backtrace
        Mail.defaults do
          delivery_method :smtp,
                          address: 'smtp.sina.cn',
                          user_name: 'otmst',
                          password: 'oTMStesting'
        end
        Mail.deliver do
          from 'otmst@sina.cn'
          to ARGV[-1]
          subject e
          body e.backtrace
        end
        break
      end
    end
  end
else
  demo.call
end
