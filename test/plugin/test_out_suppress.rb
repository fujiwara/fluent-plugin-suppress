require 'helper'

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

  def create_driver(conf = CONFIG, tag='test.info')
    Fluent::Test::OutputTestDriver.new(Fluent::SuppressOutput, tag).configure(conf)
  end

  def test_emit
    d = create_driver

    time = Time.parse("2012-11-22 11:22:33 UTC").to_i
    d.run do
      d.emit({"id" => 1, "host" => "web01", "message" => "error!!"}, time + 1)
      d.emit({"id" => 2, "host" => "web01", "message" => "error!!"}, time + 2)
      d.emit({"id" => 3, "host" => "web01", "message" => "error!!"}, time + 3)
      d.emit({"id" => 4, "host" => "web01", "message" => "error!!"}, time + 4)
      d.emit({"id" => 5, "host" => "app01", "message" => "error!!"}, time + 4)
      d.emit({"id" => 6, "host" => "web01", "message" => "error!!"}, time + 12)
      d.emit({"id" => 7, "host" => "web01", "message" => "error!!"}, time + 13)
      d.emit({"id" => 8, "host" => "web01", "message" => "error!!"}, time + 14)
    end

    emits = d.emits
    assert_equal 5, emits.length
    assert_equal ["sp.test.info", time + 1,  {"id"=>1, "host"=>"web01", "message"=>"error!!"}], emits[0]
    assert_equal ["sp.test.info", time + 2,  {"id"=>2, "host"=>"web01", "message"=>"error!!"}], emits[1]
    assert_equal ["sp.test.info", time + 4,  {"id"=>5, "host"=>"app01", "message"=>"error!!"}], emits[2]
    assert_equal ["sp.test.info", time + 12, {"id"=>6, "host"=>"web01", "message"=>"error!!"}], emits[3]
    assert_equal ["sp.test.info", time + 13, {"id"=>7, "host"=>"web01", "message"=>"error!!"}], emits[4]

  end

  def test_emit_wtih_nested_key
    d = create_driver(CONFIG_WITH_NESTED_KEY)

    time = Time.parse("2012-11-22 11:22:33 UTC").to_i
    d.run do
      d.emit({"id" => 1, "data" => {"host" => "web01", "message" => "error!!"}}, time + 1)
      d.emit({"id" => 2, "data" => {"host" => "web01", "message" => "error!!"}}, time + 2)
      d.emit({"id" => 3, "data" => {"host" => "web01", "message" => "error!!"}}, time + 3)
      d.emit({"id" => 4, "data" => {"host" => "web01", "message" => "error!!"}}, time + 4)
      d.emit({"id" => 5, "data" => {"host" => "app01", "message" => "error!!"}}, time + 4)
      d.emit({"id" => 6, "data" => {"host" => "web01", "message" => "error!!"}}, time + 12)
      d.emit({"id" => 7, "data" => {"host" => "web01", "message" => "error!!"}}, time + 13)
      d.emit({"id" => 8, "data" => {"host" => "web01", "message" => "error!!"}}, time + 14)
    end

    emits = d.emits
    assert_equal 5, emits.length
    assert_equal ["sp.test.info", time + 1,  {"id"=>1, "data" => {"host"=>"web01", "message"=>"error!!"}}], emits[0]
    assert_equal ["sp.test.info", time + 2,  {"id"=>2, "data" => {"host"=>"web01", "message"=>"error!!"}}], emits[1]
    assert_equal ["sp.test.info", time + 4,  {"id"=>5, "data" => {"host"=>"app01", "message"=>"error!!"}}], emits[2]
    assert_equal ["sp.test.info", time + 12, {"id"=>6, "data" => {"host"=>"web01", "message"=>"error!!"}}], emits[3]
    assert_equal ["sp.test.info", time + 13, {"id"=>7, "data" => {"host"=>"web01", "message"=>"error!!"}}], emits[4]

  end

  def test_emit_tagonly
    d = create_driver(CONFIG_TAG_ONLY)

    time = Time.parse("2012-11-22 11:22:33 UTC").to_i
    d.run do
      d.emit({"id" => 1, "host" => "web01", "message" => "1 error!!"}, time + 1)
      d.emit({"id" => 2, "host" => "web02", "message" => "2 error!!"}, time + 2)
      d.emit({"id" => 3, "host" => "web03", "message" => "3 error!!"}, time + 3)
      d.emit({"id" => 4, "host" => "web04", "message" => "4 error!!"}, time + 4)
      d.emit({"id" => 5, "host" => "app05", "message" => "5 error!!"}, time + 4)
      d.emit({"id" => 6, "host" => "web06", "message" => "6 error!!"}, time + 12)
      d.emit({"id" => 7, "host" => "web07", "message" => "7 error!!"}, time + 13)
      d.emit({"id" => 8, "host" => "web08", "message" => "8 error!!"}, time + 14)
    end

    emits = d.emits
    assert_equal 4, emits.length
    assert_equal ["sp.test.info", time + 1,  {"id"=>1, "host"=>"web01", "message"=>"1 error!!"}], emits[0]
    assert_equal ["sp.test.info", time + 2,  {"id"=>2, "host"=>"web02", "message"=>"2 error!!"}], emits[1]
    assert_equal ["sp.test.info", time + 12, {"id"=>6, "host"=>"web06", "message"=>"6 error!!"}], emits[2]
    assert_equal ["sp.test.info", time + 13, {"id"=>7, "host"=>"web07", "message"=>"7 error!!"}], emits[3]
  end

end
