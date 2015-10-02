require 'yaml'
require 'recursive-open-struct'
require 'rest-client'

module Otms
  # methods set for load data
  module LoadData
    attr_reader :config

    def initialize_data(data)
      data.class == Hash ? data : YAML.load_file(data)
    end

    def symbol_hash(hash)
      Hash[hash.map { |(k, v)| [k.to_sym, v] }]
    end

    def config
      @config ? @config : RecursiveOpenStruct.new(initialize_data("#{$cur_path}/config.yml"))
    end

    def url
      ssl_url = "https://#{config.url[config.env]}"
      resource = RestClient::Resource.new(
        ssl_url, verify_ssl: OpenSSL::SSL::VERIFY_NONE)
      resource.get
      ssl_url
    rescue StandardError
      ssl_url.gsub('https:', 'http:')
    end

    YAML.load_file("#{File.dirname(__FILE__)}/../../config.yml")['app_path'].each do |app, path|
      define_method("#{app}_url") { "#{url}#{path}" }       #return otms_url or xtt_url
    end

    YAML.load_file("#{File.dirname(__FILE__)}/../../config.yml")['sub_app_path'].each do |app, path|
      define_method("#{app}_url") { "#{otms_url.split('/').join('/')}#{path}" }  #return mam_url or ws_url
    end

    def current_lang
      config.lang
    end

    def other_lang
      config.i18n.reject { |e| e == current_lang }.first
    end

    def class_file_name
      self.class.name.split(':').last
        .gsub(/[A-Z]/) { |v| "_#{v.downcase}" }.gsub(/^_/, '')
    end

    def class_file
      "#{$cur_path}/bin/object/#{class_file_name}.yml"
    end

    %w(data check).each do |var|
      define_method("#{var}_file") do
        "#{$cur_path}/bin/data/#{class_file_name}_#{var}.yml"
      end
    end

    %w(common filter popup table_header preview).each do |y|
      define_method("#{y}_file") { "#{$cur_path}/bin/object/_#{y}.yml" }
    end

    def attribute
      %w(node
         class
         text
         xpath
         type
         src
         id
         index)
    end

    def assign_category(hash)
      local_category = hash.delete('category')
      hash.each do |_key, value|
        value.merge!('category' => local_category) unless value['category']
      end
      hash
    end

    def without_other_object?(hash)
      !hash.keys.reject { |k| k == 'category' }
        .reject { |v| attribute.include?(v) || config.i18n.include?(v) }
        .empty?
    end

    def decode(hash)
      if hash.key?('category') &&
         hash['category'] != 'table' &&
         without_other_object?(hash)
        assign_category(hash)
      else
        hash
      end
    end

    def decode_key(parent_key, key)
      "#{parent_key}_#{key}".gsub(/^_/, '')
    end

    def read_new_hash(parent_key, key, value)
      @new_key = decode_key(parent_key, key)
      @new_value = decode(value)
    end

    def write_out_new_hash
      @new_hash = {} unless @new_hash
      @new_hash[@new_key] = @new_value
    end

    def rehash(hash, parent_key:nil)
      hash.each do |key, value|
        if value.is_a?(Hash)
          read_new_hash(parent_key, key, value)
          rehash(value, parent_key: decode_key(parent_key, key))
        else
          write_out_new_hash
          break
        end
      end
    end

    def decode_category(hash)
      category = initialize_data("#{$cur_path}/bin/object/_category.yml")
      hash.each do |_key, value|
        next unless value.is_a?(Hash) &&
                    value.key?('category') &&
                    value['category'] != 'table'
        local_category = category[value.delete('category')]
        value.merge!(local_category)
      end
      hash
    end

    def decode_hash(hash)
      rehash(hash)
      new_hash = @new_hash
      @new_hash = nil
      @new_value = nil
      decode_category(new_hash)
    end

    def decode_file(file)
      decode_hash(initialize_data(file))
    end

    def decode_value(hash)
      hash.each do |key, value|
        hash[key] =
          if value.respond_to?('[]') && value[0] == '/' && value[-1] == '/'
            /#{value.gsub("/", "")}/
          else
            value
          end
      end
      hash
    end

    def decode_text(hash)
      hash.select { |k, _v| config.i18n.include?(k.to_s) }
    end

    def decode_attr(hash, lang:nil)
      text = decode_text(hash)
      hash.reject! { |k, _v| config.i18n.include?(k.to_s) }
      hash.merge!(text: text[lang.to_sym]).select! { |_k, v| v }
      decode_value(hash).reject { |k, _v| k == :node || k == :var_name }
    end

    def decode_table(parent, hash)
      table_attr ||= { class: 'v-table-table' }
      return unless hash[:row]
      row_object = parent.table(table_attr).send('[]', hash[:row].to_i)
      return row_object unless hash[:col]
      cell_object = row_object.send('[]', hash[:col].to_i)
      return cell_object unless hash[:sub]
      cell_object.send(hash[:sub])
    end

    def object_accessor(parent, hash, lang)
      if hash[:category] == 'table'
        instance_variable_set("@#{hash[:var_name]}", decode_table(parent, hash))
      else
        instance_variable_set(
          "@#{hash[:var_name]}",
          parent.send(hash[:node], decode_attr(hash, lang: lang)))
      end
      define_object_accessor(hash)
    end

    def define_object_accessor(hash)
      define_singleton_method(hash[:var_name]) do
        instance_variable_get("@#{hash[:var_name]}")
      end
      define_singleton_method("#{hash[:var_name]}_hash") { hash }
    end

    def object_array(hash)
      array = []
      hash.define_singleton_method(:to_attr) do
        first = shift
        str_hash = { var_name: first[0] }.merge(first[1])
        Hash[str_hash.map { |k, v| [k.to_sym, v] }]
      end
      hash.each { array << hash.to_attr }
      array
    end

    def load_object(file = nil, hash:nil, lang:nil, parent:nil)
      file ||= class_file
      hash ||= decode_file(file)
      lang ||= current_lang
      parent ||= sys
      object_array(hash).each { |h| object_accessor(parent, h, lang) }
    end

    def load_filters(file = nil, hash:nil, parent:nil, index:0)
      load_object(
        file,
        hash: hash,
        parent: parent.div(class: 'filters-panel', index: index))
    end

    def load_preview_object
      load_object(popup_file, parent: popup_content)
      initialize_data(popup_file)['preview']
        .keys.reject { |k| k == 'category' }.each do |key|
        next unless initialize_data(preview_file).key?(key)
        load_preview_object_node(key)
      end
    end

    def load_preview_object_node(node)
      load_object(
        hash: decode_hash('preview' => initialize_data(preview_file)[node]),
        parent: send("preview_#{node}"))
    end

    def time_remark
      Time.new.strftime('%Y%m%d%H%M%S%L')
    end

    def next_work_day
      now = Time.now
      date = Date.new(now.year, now.month, now.day)
      loop do
        date += 1
        break if date.monday?
      end
      date
    end
  end
end
