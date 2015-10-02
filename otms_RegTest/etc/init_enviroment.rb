require 'yaml'

config_file = 'config.yml'
config = YAML.load_file(config_file)
config['env'] = ARGV[0]
config['url'][config['env']] = ARGV[1] if ARGV[1]
File.open(config_file, 'w+:UTF-8') { |f| f.puts config.to_yaml }
%w(key.yml init_data.yml).each { |f| File.delete(f) if File.exist?(f) }
