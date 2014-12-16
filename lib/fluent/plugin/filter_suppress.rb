# -*- coding: utf-8 -*-
module Fluent
  class SuppressFilter < Filter
    Fluent::Plugin.register_filter('suppress', self)

    config_param :attr_keys,     :string,  :default => nil
    config_param :num,           :integer, :default => 3
    config_param :interval,      :integer, :default => 300

    def configure(conf)
      super
      @keys  = @attr_keys ? @attr_keys.split(/ *, */) : nil
      @slots = {}
    end

    def start
      super
    end

    def shutdown
      super
    end

    def filter_stream(tag, es)
      new_es = MultiEventStream.new
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

        slot.push(time.to_f)
        new_es.add(time, record)
      end
      return new_es
    end
  end if defined?(Filter) # Support only >= v0.12
end
