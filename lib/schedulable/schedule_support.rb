module Schedulable

  module ScheduleSupport

    def self.param_names
      [:id, :date, :time, :time_end, :rule, :until, :count, :interval, day: [], day_of_week: [monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: []]]
    end

  end
end
