require 'nokogiri'
require 'awesome_print'

module Otms
  # methods set for output report
  module Report
    def report_path
      "#{$cur_path}/bin/report"
    end

    def report_title
      self.class.name.split(':').last
        .gsub(/[A-Z]/) { |v| " #{v}" }.gsub(/^\s/, '')
    end

    def template_file
      "#{report_path}/template/template.html"
    end

    def report_time
      Time.new.strftime('%Y.%m.%d %H:%M:%S')
    end

    def write_out_new_template(start_time, file)
      html = File.new(file, 'w+:UTF-8')
      File.foreach(template_file) do |line|
        reline = line.strip
        html.puts report_title if reline == '</title>' || reline == '</h1>'
        html.puts start_time if reline == '</p>'
        html.puts line
      end
      html.close
    end

    def update_start_time(start_time, file)
      html = Nokogiri::HTML(File.open(file))
      p html.at_css('p')
     # p  "#{File.dirname(__FILE__)}/../../bin/report"
      html.at_css('p').content = start_time
      File.open(file, 'w+:UTF-8') { |f| f.puts html.to_html }
    end

    def initialize_template(file)
      file ||= "#{report_path}/#{class_file_name}.html"
      start_time = "Started at #{report_time}"

      if File.exist?(file)
        update_start_time(start_time, file)
      else
        write_out_new_template(start_time, file)
      end
    end

    def debug_output(actual, expected, title)
      text1 = "actual: #{actual}"
      text2 = "expected: #{expected}"
      line_size = 60
      title_size = title ? (line_size - title.size) / 2 : line_size / 2
      puts "#{'-' * title_size}#{title}#{'-' * title_size}"
      ap text1, color: { string: :red }
      ap text2, color: { string: :green }
      puts '-' * line_size
    end

    def assert_equal(actual, expected, title:nil)
      if actual == expected
        'Pass'
      else
        debug_output(actual, expected, title)
        'Fail'
      end
    end

    def assert_true(condition)
      condition ? 'Pass' : 'Fail'
    end

    def assert_array(array)
      array.uniq == ['Pass'] ? 'Pass' : 'Fail'
    end
  end
end
