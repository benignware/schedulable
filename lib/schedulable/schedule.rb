module Schedulable
  module Model
    class Schedule  < ActiveRecord::Base
      
      serialize :day
      serialize :day_of_week, Hash
    
      belongs_to :schedulable, polymorphic: true
    
      after_initialize :update_schedule
      before_save :update_schedule
      
      validates_presence_of :rule
      validates_presence_of :time
      validates_presence_of :date, if: Proc.new { |schedule| schedule.rule == 'singular' }
      validate :validate_day, if: Proc.new { |schedule| schedule.rule == 'weekly' }
      validate :validate_day_of_week, if: Proc.new { |schedule| schedule.rule == 'monthly' }
      
      def to_icecube
        return @schedule
      end
      
      def to_s
        return @schedule.to_s
      end
      
      def method_missing(meth, *args, &block)
        if @schedule.present? && @schedule.respond_to?(meth)
          @schedule.send(meth, *args, &block)
        end
      end
      
      def self.param_names
        [:id, :date, :time, :rule, :until, :count, :interval, day: [], day_of_week: [monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: []]]
      end
    
      def update_schedule()
        
        self.rule||= "singular"
        self.interval||= 1
        self.count||= 0

        @schedule = IceCube::Schedule.new(Time.now)
        
        if self.rule && self.rule != 'singular'
          
          self.interval = self.interval.present? ? self.interval.to_i : 1
          
          rule = IceCube::Rule.send("#{self.rule}", self.interval)
          
          if self.until
            rule.until(self.until)
          end
          
          if self.count && self.count.to_i > 0
            rule.count(self.count.to_i)
          end
        
          if self.day
            days = self.day.reject(&:empty?)
            if self.rule == 'weekly'
              days.each do |day|
                rule.day(day.to_sym)
              end
            elsif self.rule == 'monthly'
              days = {}
              day_of_week.each do |weekday, value|
                days[weekday.to_sym] = value.reject(&:empty?).map { |x| x.to_i }
              end
              rule.day_of_week(days)
            end
          end
          @schedule.add_recurrence_rule(rule)
        end
        
      end
      
      private
      
      def validate_day
        day.reject! { |c| c.empty? }
        if !day.any?
          errors.add(:day, :empty)
        end
      end
      
      def validate_day_of_week
        any = false
        day_of_week.each { |key, value|
          value.reject! { |c| c.empty? }
          if value.length > 0
            any = true
            break
          end
        }
        if !any
          errors.add(:day_of_week, :empty)
        end
      end
    end
  end
end