module Fluent
  class CollectdUnrollOutput < Output
    Fluent::Plugin.register_output('collectd_unroll', self)

    config_param :remove_tag_prefix,  :string, :default => nil
    config_param :add_tag_prefix,     :string, :default => nil


    def emit(tag, es, chain)
      tag = update_tag(tag)
      es.each { |time, record|
        router.emit(tag, time, normalize_record(record))
      }

      chain.next
    end


    def update_tag(tag)
      if remove_tag_prefix
        if remove_tag_prefix == tag
          tag = ''
        elsif tag.to_s.start_with?(remove_tag_prefix+'.')
          tag = tag[remove_tag_prefix.length+1 .. -1]
        end
      end
      if add_tag_prefix
        tag = tag && tag.length > 0 ? "#{add_tag_prefix}.#{tag}" : add_tag_prefix
      end
      return tag
    end

    private

    def normalize_record(record)
      if record.nil?
        return record
      end
      if !(record.has_key?('values')) || !(record.has_key?('dsnames')) || !(record.has_key?('dstypes')) || !(record.has_key?('host')) || !(record.has_key?('plugin')) || !(record.has_key?('plugin_instance')) || !(record.has_key?('type')) || !(record.has_key?('type_instance'))
        return record
      end
      
      record['values'].each_with_index { |value, index|
        @tags = [record['host'].gsub(".","/"), record['plugin'], record['plugin_instance'], record['type'], record['type_instance'], record['dsnames'][index]]
        tag = @tags.join(".").squeeze(".").gsub(/\.$/, '')
        record[tag] = value
        record[record['dsnames'][index]] = value
        record['dstype_' + record['dsnames'][index]] = record['dstypes'][index]
        record['dstype'] = record['dstypes'][index]
      }
      record.delete('dstypes')
      record.delete('dsnames')
      record.delete('values')
      record
    end
  end
end
