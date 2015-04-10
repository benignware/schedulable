require 'test_helper'
require 'database_cleaner'

class SchedulableTest < ActiveSupport::TestCase
  puts "HELLO"
  
  DatabaseCleaner.clean_with(:truncation)
  DatabaseCleaner.start
  
  event = FactoryGirl.create(:event)
  puts event.name

  test "truth" do
    assert_kind_of Module, Schedulable
  end
end