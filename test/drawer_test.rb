require 'test/unit'
require 'rubygems'
require 'contest'

require File.join(File.dirname(__FILE__), '../lib/drawer')

def cache_file
  @cache_file ||= File.join(File.dirname(__FILE__), 'db/test.yml')
end

class TestDrawer < Test::Unit::TestCase
  context "drawer" do
    setup do
      Drawer.create(cache_file)
      @drawer = Drawer.new(cache_file)
      @drawer.flush_all
    end

    should "return nil if a key is not found" do
      assert_nil @drawer.get("foo")
    end

    should "set a key with a block on a cache miss" do
      assert_equal 123, @drawer.get("foo") { 123 }
      assert_nothing_raised { @drawer.get("foo") { raise 'Should not call block.' } }
    end

    should "successfully set a key" do
      @drawer.set("foo", 123)

      assert_equal 123, @drawer.get("foo")
      assert_equal 124, @drawer.set("foo", 124)
    end

    should "clear an entry with remove" do
      @drawer.set("foo", 123)
      @drawer.remove("foo")
      assert_nil @drawer.get("foo")
    end

    context "flush_all" do
      setup do
        @drawer.set("foo", 123)
        @drawer.flush_all
      end

      should "clear all keys" do
        assert_nil @drawer.get("foo")
      end
    end

    context "get_multi" do
      setup do
        10.times do |i|
          @drawer.set(i, i * i)
        end
      end

      should "return a list of values" do
        assert_equal [9, 25, 49], @drawer.get_multi(3, 5, 7)
      end
    end

    context "class methods" do
      setup do
        Drawer.remove(cache_file)
        Drawer.create(cache_file)
      end

      context "open an existent file" do
        should "return an instance of Drawer" do
          assert_kind_of Drawer, Drawer.open(cache_file)
        end
      end

      context "open with block" do
        should "call the passed block" do
          drawer = Drawer.open(cache_file) do |cache|
            cache.set("foo", 123)
          end
          assert_equal 123, drawer.get('foo')
        end
      end
    end

    context "class methods with unexistent file" do
      setup do
        Drawer.remove(cache_file)
      end

      context "open a not existent file" do
        should "raise if the file doesn't exist" do
          assert_raise Errno::ENOENT do
            Drawer.open(cache_file)
          end
        end

        should "not create the file" do
          Drawer.open(cache_file) rescue Errno::ENOENT
          assert_equal false, File.exists?(cache_file)
        end
      end

      context "open!" do
        should "create the file" do
          Drawer.open!(cache_file)
          assert_equal true, File.exists?(cache_file)
        end
      end
    end
  end
end
