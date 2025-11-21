require 'test_helper'
require 'database_cleaner-active_record'

class SchedulableTest < ActiveSupport::TestCase
  setup do
    @event = FactoryBot.create(:event)
  end

  test "module exists" do
    assert_kind_of Module, Schedulable
  end

  test "can create event with schedule" do
    assert_not_nil @event.schedule
    assert_equal 'weekly', @event.schedule.rule
  end

  test "schedule has correct attributes" do
    schedule = @event.schedule
    assert_equal ['monday'], schedule.day
    assert_equal 10, schedule.count
    assert_instance_of Time, schedule.time.to_time
  end

  test "schedule generates occurrences" do
    schedule = @event.schedule
    occurrences = schedule.occurrences(Time.current + 2.months)
    assert_not_empty occurrences
    assert_instance_of Array, occurrences
    assert occurrences.all? { |o| o.is_a?(Time) }
  end

  test "schedule serializes day attribute correctly" do
    schedule = FactoryBot.create(:schedule, day: ['monday', 'wednesday'])
    schedule.reload
    assert_equal ['monday', 'wednesday'], schedule.day
  end

  test "schedule serializes day_of_week attribute correctly" do
    day_of_week = { 'monday' => [1, 3], 'wednesday' => [2, 4] }
    schedule = FactoryBot.create(:schedule, rule: 'monthly', day_of_week: day_of_week)
    schedule.reload
    assert_equal day_of_week, schedule.day_of_week
  end
end