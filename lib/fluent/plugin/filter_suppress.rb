require 'fluent/plugin/filter'

module Fluent::Plugin
  class SuppressFilter < Fluent::Plugin::Filter
    Fluent::Plugin.register_filter('suppress', self)

    config_param :attr_keys,     :string,  default: nil
    config_param :num,           :integer, default: 3
    config_param :max_slot_num,  :integer, default: 100000
    config_param :interval,      :integer, default: 300

    def configure(conf)
      super
      @keys  = @attr_keys ? @attr_keys.split(/ *, */) : nil
      @slots = {}
    end

    def filter_stream(tag, es)
      new_es = Fluent::MultiEventStream.new
      es.each do |time, record|
        if @keys
          keys = @keys.map do |key|
            key.split(/\./).inject(record) {|r, k| r[k] }
          end
          key = tag + "\0" + keys.join("\0")
        else
          key = tag
        end
        slot = @slots[key] ||= []

        # expire old records time
        expired = time.to_f - @interval
        while slot.first && (slot.first <= expired)
          slot.shift
        end

        if slot.length >= @num
          log.debug "suppressed record: #{record.to_json}"
          next
        end

        if @slots.length > @max_slot_num
          (evict_key, evict_slot) = @slots.shift
          if evict_slot.last && (evict_slot.last > expired)
            log.warn "@slots length exceeded @max_slot_num: #{@max_slot_num}. Evicted slot for the key: #{evict_key}"
          end
        end

        slot.push(time.to_f)
        new_es.add(time, record)
      end
      return new_es
    end
  end
end
