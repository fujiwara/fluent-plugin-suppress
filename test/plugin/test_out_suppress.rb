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
end
