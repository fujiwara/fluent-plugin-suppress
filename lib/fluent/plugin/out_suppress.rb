# -*- coding: utf-8 -*-
module Fluent
  class SuppressOutput < Output
    include Fluent::HandleTagNameMixin

    Fluent::Plugin.register_output('suppress', self)

    config_param :attr_keys,     :string,  :default => nil
    config_param :num,           :integer, :default => 3
    config_param :interval,      :integer, :default => 300

    unless method_defined?(:log)
      define_method("log") { $log }
    end

    # Define `router` method of v0.12 to support v0.10 or earlier
    unless method_defined?(:router)
      define_method("router") { Fluent::Engine }
    end

    def configure(conf)
      super

      @labelled = !conf['@label'].nil?

      if !@labelled && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix
        raise ConfigError, "out_suppress: Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix."
      end

      @keys  = @attr_keys ? @attr_keys.split(/ *, */) : nil
      @slots = {}
    end

    def start
      super
    end

    def shutdown
      super
    end

    def emit(tag, es, chain)
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
        _tag = tag.clone
        filter_record(_tag, time, record)
        if @labelled || tag != _tag
          router.emit(_tag, time, record)
        else
          log.warn "Drop record #{record} tag '#{tag}' was not replaced. Can't emit record, cause infinity looping. Set remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix correctly."
        end
      end

      chain.next
    end
  end
end
