require 'fluent/plugin/filter'

module Fluent::Plugin
  class SuppressFilter < Fluent::Plugin::Filter
    Fluent::Plugin.register_filter('suppress', self)

    config_param :attr_keys,     :string,  default: nil
    config_param :num,           :integer, default: 3
    config_param :interval,      :integer, default: 300
    config_param :give_feedback, :string,  default: nil

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

        if should_suppress?(slot: slot, number_to_keep: @num)
          log.debug "suppressed record: #{record.to_json}"
          suppressed_count += 1
          next
        end

        slot.push(record_time.to_f)
        new_es.add(record_time, record)
      end

      optionally_give_feedback(event_stream: new_es, count: suppressed_count)
      new_es
    end

    private

    def optionally_give_feedback(event_stream:, count:)
      if option_give_feedback? && count > 0
        log.debug "Suppressed #{count} records"
        event_stream.add(current_time, {'message' => "And #{count} more..."})
      end
    end

    def should_suppress?(slot:, number_to_keep:)
      slot.length >= number_to_keep
    end

    def option_give_feedback?
      !@give_feedback.nil? && @give_feedback.to_s.downcase == 'yes'
    end

    def current_time
      Time.now.getlocal.to_f
    end
  end
end
