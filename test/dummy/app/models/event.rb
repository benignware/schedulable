class Event < ActiveRecord::Base
  acts_as_schedulable :schedule, occurrences: :event_occurrences
end
