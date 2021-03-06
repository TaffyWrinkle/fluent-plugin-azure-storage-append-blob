require 'helper'
require 'fluent/plugin/out_azure-storage-append-blob.rb'

include Fluent::Test::Helpers

class AzureStorageAppendBlobOutTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  CONFIG = %[
    azure_storage_account test_storage_account
    azure_storage_access_key MY_FAKE_SECRET
    azure_container test_container
    time_slice_format        %Y%m%d-%H
    path log
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::AzureStorageAppendBlobOut).configure(conf)
  end

  sub_test_case 'test config' do
    test 'config should reject with no azure container' do
      assert_raise Fluent::ConfigError do
        create_driver(%[
          azure_storage_account test_storage_account
          azure_storage_access_key MY_FAKE_SECRET
          time_slice_format        %Y%m%d-%H
          time_slice_wait          10m
          path log
        ])
      end
    end

     test 'config should set instance variables' do
      d = create_driver
      assert_equal 'test_storage_account', d.instance.azure_storage_account
      assert_equal 'MY_FAKE_SECRET', d.instance.azure_storage_access_key
      assert_equal 'test_container', d.instance.azure_container
      assert_equal true, d.instance.auto_create_container
      assert_equal '%{path}%{time_slice}-%{index}.log', d.instance.azure_object_key_format
    end
  end

  sub_test_case 'test path slicing' do
    test 'test path_slicing' do
      config = CONFIG.clone.gsub(/path\slog/, "path log/%Y/%m/%d")
      d = create_driver(config)
      path_slicer = d.instance.instance_variable_get(:@path_slicer)
      path = d.instance.instance_variable_get(:@path)
      slice = path_slicer.call(path)
      assert_equal slice, Time.now.utc.strftime("log/%Y/%m/%d")
    end

    test 'path slicing utc' do
      config = CONFIG.clone.gsub(/path\slog/, "path log/%Y/%m/%d")
      config << "\nutc\n"
      d = create_driver(config)
      path_slicer = d.instance.instance_variable_get(:@path_slicer)
      path = d.instance.instance_variable_get(:@path)
      slice = path_slicer.call(path)
      assert_equal slice, Time.now.utc.strftime("log/%Y/%m/%d")
    end
  end
end
