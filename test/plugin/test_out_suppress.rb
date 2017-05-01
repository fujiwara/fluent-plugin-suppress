require 'helper'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_suppress'

class SuppressOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    interval       10
    num            2
    attr_keys      host, message
    add_tag_prefix sp.
  ]

  CONFIG_WITH_NESTED_KEY = %[
    interval       10
    num            2
    attr_keys      data.host, data.message
    add_tag_prefix sp.
  ]

  CONFIG_TAG_ONLY = %[
    interval       10
    num            2
    add_tag_prefix sp.
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::SuppressOutput).configure(conf)
  end

  def test_emit
    d = create_driver

    time = event_time("2012-11-22 11:22:33 UTC")
    d.run(default_tag: "test.info") do
      d.feed(time + 1,  {"id" => 1, "host" => "web01", "message" => "error!!"})
      d.feed(time + 2,  {"id" => 2, "host" => "web01", "message" => "error!!"})
      d.feed(time + 3,  {"id" => 3, "host" => "web01", "message" => "error!!"})
      d.feed(time + 4,  {"id" => 4, "host" => "web01", "message" => "error!!"})
      d.feed(time + 4,  {"id" => 5, "host" => "app01", "message" => "error!!"})
      d.feed(time + 12, {"id" => 6, "host" => "web01", "message" => "error!!"})
      d.feed(time + 13, {"id" => 7, "host" => "web01", "message" => "error!!"})
      d.feed(time + 14, {"id" => 8, "host" => "web01", "message" => "error!!"})
    end

    events = d.events
    assert_equal 5, events.length
    assert_equal ["sp.test.info", time + 1,  {"id"=>1, "host"=>"web01", "message"=>"error!!"}], events[0]
    assert_equal ["sp.test.info", time + 2,  {"id"=>2, "host"=>"web01", "message"=>"error!!"}], events[1]
    assert_equal ["sp.test.info", time + 4,  {"id"=>5, "host"=>"app01", "message"=>"error!!"}], events[2]
    assert_equal ["sp.test.info", time + 12, {"id"=>6, "host"=>"web01", "message"=>"error!!"}], events[3]
    assert_equal ["sp.test.info", time + 13, {"id"=>7, "host"=>"web01", "message"=>"error!!"}], events[4]

  end

  def test_emit_wtih_nested_key
    d = create_driver(CONFIG_WITH_NESTED_KEY)

    time = event_time("2012-11-22 11:22:33 UTC")
    d.run(default_tag: "test.info") do
      d.feed(time + 1,  {"id" => 1, "data" => {"host" => "web01", "message" => "error!!"}})
      d.feed(time + 2,  {"id" => 2, "data" => {"host" => "web01", "message" => "error!!"}})
      d.feed(time + 3,  {"id" => 3, "data" => {"host" => "web01", "message" => "error!!"}})
      d.feed(time + 4,  {"id" => 4, "data" => {"host" => "web01", "message" => "error!!"}})
      d.feed(time + 4,  {"id" => 5, "data" => {"host" => "app01", "message" => "error!!"}})
      d.feed(time + 12, {"id" => 6, "data" => {"host" => "web01", "message" => "error!!"}})
      d.feed(time + 13, {"id" => 7, "data" => {"host" => "web01", "message" => "error!!"}})
      d.feed(time + 14, {"id" => 8, "data" => {"host" => "web01", "message" => "error!!"}})
    end

    events = d.events
    assert_equal 5, events.length
    assert_equal ["sp.test.info", time + 1,  {"id"=>1, "data" => {"host"=>"web01", "message"=>"error!!"}}], events[0]
    assert_equal ["sp.test.info", time + 2,  {"id"=>2, "data" => {"host"=>"web01", "message"=>"error!!"}}], events[1]
    assert_equal ["sp.test.info", time + 4,  {"id"=>5, "data" => {"host"=>"app01", "message"=>"error!!"}}], events[2]
    assert_equal ["sp.test.info", time + 12, {"id"=>6, "data" => {"host"=>"web01", "message"=>"error!!"}}], events[3]
    assert_equal ["sp.test.info", time + 13, {"id"=>7, "data" => {"host"=>"web01", "message"=>"error!!"}}], events[4]

  end

  def test_emit_tagonly
    d = create_driver(CONFIG_TAG_ONLY)

    time = event_time("2012-11-22 11:22:33 UTC")
    d.run(default_tag: "test.info") do
      d.feed(time + 1,  {"id" => 1, "host" => "web01", "message" => "1 error!!"})
      d.feed(time + 2,  {"id" => 2, "host" => "web02", "message" => "2 error!!"})
      d.feed(time + 3,  {"id" => 3, "host" => "web03", "message" => "3 error!!"})
      d.feed(time + 4,  {"id" => 4, "host" => "web04", "message" => "4 error!!"})
      d.feed(time + 4,  {"id" => 5, "host" => "app05", "message" => "5 error!!"})
      d.feed(time + 12, {"id" => 6, "host" => "web06", "message" => "6 error!!"})
      d.feed(time + 13, {"id" => 7, "host" => "web07", "message" => "7 error!!"})
      d.feed(time + 14, {"id" => 8, "host" => "web08", "message" => "8 error!!"})
    end

    events = d.events
    assert_equal 4, events.length
    assert_equal ["sp.test.info", time + 1,  {"id"=>1, "host"=>"web01", "message"=>"1 error!!"}], events[0]
    assert_equal ["sp.test.info", time + 2,  {"id"=>2, "host"=>"web02", "message"=>"2 error!!"}], events[1]
    assert_equal ["sp.test.info", time + 12, {"id"=>6, "host"=>"web06", "message"=>"6 error!!"}], events[2]
    assert_equal ["sp.test.info", time + 13, {"id"=>7, "host"=>"web07", "message"=>"7 error!!"}], events[3]
  end
end
