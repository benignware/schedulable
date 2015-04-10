class Schedule < ActiveRecord::Base
  
  include Schedulable::ScheduleSupport
  
  serialize :day
  serialize :day_of_week, Hash

  belongs_to :schedulable, polymorphic: true

  after_initialize :init_schedule
  after_save :init_schedule
  
end