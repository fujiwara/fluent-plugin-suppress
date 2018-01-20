require 'fluent/plugin/filter'

module Fluent::Plugin
  class SuppressFilter < Fluent::Plugin::Filter
    Fluent::Plugin.register_filter('suppress', self)

    config_param :attr_keys,     :string,  default: nil
    config_param :num,           :integer, default: 3
    config_param :interval,      :integer, default: 300

    def configure(conf)
      super
      @keys  = @attr_keys ? @attr_keys.split(/ *, */) : nil
      @slots = {}
    end

    def filter_stream(tag, es)
      suppressed_count = 0
      new_es = Fluent::MultiEventStream.new
      es.each do |record_time, record|
        if @keys
          keys = @keys.map do |key|
            key.split(/\./).inject(record) {|r, k| r[k] }
          end
          key = tag + "\0" + keys.join("\0")
        else
          key = tag
        end
        slot = @slots[key] ||= []

        # expire old records record_time
        expired = record_time.to_f - @interval
        while slot.first && (slot.first <= expired)
          slot.shift
        end

        if should_suppress?(slot, @num)
          log.debug "suppressed record: #{record.to_json}"
          suppressed_count += 1
          next
        end

        slot.push(record_time.to_f)
        new_es.add(record_time, record)
      end

      log.debug "Suppressed #{suppressed_count} records"
      return new_es
    end

    private

    def should_suppress?(slot, number_to_keep)
      slot.length >= number_to_keep
    end
  end
end
