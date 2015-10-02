require 'yaml'

module Otms
  # methods for output data
  module Output
    def write_out_file(file, string)
      file_object = File.open(file, 'w+')
      file_object.puts string
      file_object.close
    end

    def write_out_yaml(file, hash)
      write_out_file(file, hash.to_yaml)
    end

    def write_append_yaml(file, paths = [], hash)
      yaml_object = YAML.load_file(file)
      sub_yaml = yaml_object
      paths = [paths] unless paths.respond_to?('each')
      paths.each { |path| sub_yaml = sub_yaml[path] }
      sub_yaml.merge!(hash)
      write_out_yaml(file, yaml_object)
    end

    def copy_file(from:nil, to:nil)
      write_out_file(to, File.read(from))
    end
  end
end
