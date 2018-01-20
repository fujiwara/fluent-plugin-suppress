require 'fluent/plugin/output'

module Fluent::Plugin
  class SuppressOutput < Fluent::Plugin::Output
    include Fluent::HandleTagNameMixin

    Fluent::Plugin.register_output('suppress', self)

    helpers :event_emitter

    config_param :attr_keys,     :string,  default: nil
    config_param :num,           :integer, default: 3
    config_param :interval,      :integer, default: 300

    def configure(conf)
      super

      @labelled = !conf['@label'].nil?

      if !@labelled && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix
        raise Fluent::ConfigError, 'out_suppress: Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix.'
      end

      @keys  = @attr_keys ? @attr_keys.split(/ *, */) : nil
      @slots = {}
    end

    def multi_workers_ready?
      true
    end

    def process(tag, es)
      es.each do |time, record|
        if @keys
          keys = @keys.map do |key|
            key.split(/\./).inject(record) { |r, k| r[k] }
          end
          key = tag + "\0" + keys.join("\0")
        else
          key = tag
        end
        slot = @slots[key] ||= []

        # expire old records time
        expired = time.to_f - @interval
        slot.shift while slot.first && (slot.first <= expired)

        if slot.length >= @num
          log.debug "suppressed record: #{record.to_json}"
          next
        end

        slot.push(time.to_f)
        _tag = tag.clone
        filter_record(_tag, time, record)
        if @labelled || tag != _tag
          router.emit(_tag, time, record)
        else
          log.warn "Drop record #{record} tag '#{tag}' was not replaced. Can't emit record, cause infinity looping. Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix correctly."
        end
      end
    end
  end
end
