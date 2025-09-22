module Schedulable
  module Model
    class Schedule < ActiveRecord::Base
      self.table_name = 'schedules'

      # Use Rails 7.2+ serialization
      serialize :day, coder: YAML
      serialize :day_of_week, coder: YAML

      belongs_to :schedulable, polymorphic: true

      after_initialize :set_defaults, :update_schedule
      before_save :update_schedule

      validates :rule, presence: true
      validates :time, presence: true
      validates :date, presence: true, if: -> { rule == 'singular' }
      validate :validate_day, if: -> { rule == 'weekly' }
      validate :validate_day_of_week, if: -> { rule == 'monthly' }

      delegate_missing_to :@schedule, allow_nil: true

      # Normalize AR time values to core Time for compatibility with existing tests
      def time
        value = super()
        return value if value.is_a?(Time) || value.nil?
        # ActiveRecord maps time columns to ActiveSupport::TimeWithZone
        if value.respond_to?(:in_time_zone)
          t = value.in_time_zone
          return Time.local(t.year, t.month, t.day, t.hour, t.min, t.sec)
        end
        value
      end

      def to_icecube
        @schedule
      end

      def to_s
        if rule == 'singular'
          # Return formatted datetime for singular rules
          datetime = date.to_datetime + time.seconds_since_midnight.seconds
          I18n.localize(datetime, format: :long)
        else
          # Return formatted schedule for recurring rules
          to_icecube.to_s
        end
      end

      def self.param_names
        [
          :id, :date, :time, :time_end, :rule, :until, :count, :interval,
          { day: [], day_of_week: { 
            monday: [], tuesday: [], wednesday: [], 
            thursday: [], friday: [], saturday: [], sunday: [] 
          }}
        ]
      end

      private

      def update_schedule
        # Build ice_cube schedule for singular rules when date and time exist,
        # and for recurring rules when at least time exists (use today's date as base)
        if rule && time && (date.present? || rule != 'singular')
          # Get schedule-object
          base_date = (date || Date.current)
          base_time = if defined?(Time.zone) && Time.zone
            Time.zone.local(base_date.year, base_date.month, base_date.day, time.hour, time.min, time.sec)
          else
            Time.local(base_date.year, base_date.month, base_date.day, time.hour, time.min, time.sec)
          end
          @schedule = IceCube::Schedule.new(base_time)

          case rule
          when 'singular'
            # No recurrence rule
          when 'weekly'
            days = day.map(&:to_sym) if day
            recurrence_interval = (interval.presence || 1).to_i
            rule = IceCube::Rule.weekly(recurrence_interval)
            rule = rule.day(*days) if days
            if self.until.present?
              rule = rule.until(self.until.to_time)
            elsif count.present?
              rule = rule.count(count.to_i)
            end
            @schedule.add_recurrence_rule(rule)
          when 'monthly'
            # Expect a hash like { monday: [1,3], wednesday: [2,4] }
            if day_of_week.present?
              recurrence_interval = (interval.presence || 1).to_i
              weekday_map = day_of_week.each_with_object({}) do |(weekday, week_numbers), acc|
                acc[weekday.to_sym] = Array(week_numbers).map(&:to_i)
              end
              rule = IceCube::Rule.monthly(recurrence_interval).day_of_week(weekday_map)
              if self.until.present?
                rule = rule.until(self.until.to_time)
              elsif count.present?
                rule = rule.count(count.to_i)
              end
              @schedule.add_recurrence_rule(rule)
            end
          end

          # Add exception for the seed datetime only when an explicit date is provided
          if rule != 'singular' && date.present?
            @schedule.add_exception_time(date.to_datetime + time.seconds_since_midnight.seconds)
          end
        end
      end

      def set_defaults
        # Ensure sensible default for interval on recurring rules
        if rule.present? && rule != 'singular'
          self.interval = 1 if interval.blank?
        end
      end

      def validate_day
        if rule == 'weekly' && day.empty?
          errors.add(:day, :empty)
        end
      end

      def validate_day_of_week
        if rule == 'monthly' && day_of_week.empty?
          errors.add(:day_of_week, :empty)
        end
      end
    end
  end
end
