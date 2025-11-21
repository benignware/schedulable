class Event < ActiveRecord::Base
  acts_as_schedulable :schedule, occurrences: { name: :event_occurrences }
end
