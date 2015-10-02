require_relative '../load_path'
require 'terminal-table'
require 'term/ansicolor'
require 'lib/common/report'
require 'lib/api'
require 'bin/_workflow'

module Otms
  # patch color methods to String
  class String
    include Term::ANSIColor
  end

  # Super class for test case
  class Case
    attr_reader :api
    attr_accessor :results
    include Report
    include Workflow

    def before_all
      report
      @results = []
      @api = Otms::Api.new(report: @report_file)
      initialize_otms unless self.class.to_s =~ /Api.*/
    end

    def scenario_100_clear_temp
      instance_variables.select { |v| v[1..4] == 'temp' }
        .each { |t| File.delete(instance_variable_get(t)) }
    end

    def sorted_methods
      methods.sort_by { |v| v[/scenario_\d+_/].to_s.delete('scenario_').to_i }
    end

    def output_scenario(scenario)
      scenarios = scenario.to_s.split('_')
      scenarios[1] << ':'
      scenarios[2].capitalize!
      scenarios.join(' ')
    end

    def process
      before_all
      sorted_methods.each do |m|
        next unless m[0..7] == 'scenario'
        unless m == :scenario_100_clear_temp
          puts "Running #{output_scenario(m)}"
        end
        send m
      end
      after_all
    end

    def run_scenario(index)
      send(methods.select { |m| m =~ /scenario_#{index}.*/ }[0])
    end

    def after_all
      report
      output_result
      exit if login
    end

    def output_result
      output_in_terminal
      output_to_log
      result = results.uniq == ['Pass'] ? 'Pass'.green : 'Fail'.red
      puts "Final result: #{result}"
    end

    def output_in_terminal
      result_detail = []
      results.map! { |r| r.is_a?(Array) ? assert_array(r) : r }
      results.each_with_index do |r, i|
        r = r == 'Pass' ? r.green : r.red
        result_detail << [i, r]
      end
      result_table = Terminal::Table.new(title: @report_step,
                                         headings: %w(Scenario Result),
                                         rows: result_detail)
      puts result_table
    end

    def output_to_log
      file_name = @report_file ? @report_file.split(/\W/)[-2] : 'case'
      file = File.open("log/#{file_name}.log", 'a:UTF-8')
      file.puts Time.new
      results.each_with_index { |r, i| file.puts "scenario #{i}: #{r}" }
      file.puts
      file.close
    end

    def assert_noko_node(response, key, value, result)
      response.css(key).each do |k|
        results[result] << assert_equal(k.text, value)
      end
    end

    def assert_noko_response(response, check_set = {}, result: nil)
      results[result] = []
      check_set.each do |k, v|
        assert_noko_node(response, k, v, result)
        results[result] << assert_equal(response.css(k).size, 2)
      end
    end
  end
end
