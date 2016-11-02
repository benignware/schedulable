module Schedulable
  module Model
    class Schedule  < ActiveRecord::Base

      serialize :day
      serialize :day_of_week, Hash

      belongs_to :schedulable, polymorphic: true

      after_initialize :init_schedule
      after_save :init_schedule
      
      before_save :update_schedule
      before_update :update_schedule

      validates_presence_of :rule
      validates_presence_of :time
      validates_presence_of :date, if: Proc.new { |schedule| schedule.rule == 'singular' }
      validate :validate_day, if: Proc.new { |schedule| schedule.rule == 'weekly' }
      validate :validate_day_of_week, if: Proc.new { |schedule| schedule.rule == 'monthly' }

      def to_icecube
        return @schedule
      end

      def to_s
        message = ""
        if self.rule == 'singular'
          # Return formatted datetime for singular rules
          d = DateTime.now
          date = self.date
          time = self.time
          time_zone = self.respond_to?('time_zone') ? self.send('time_zone') : Time.zone.now.zone.to_s
          if time
            puts 'time_zone: ' + self.time_zone + " --- " + time_zone
          
            datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time_zone)
            puts "****" + datetime.to_s + " ---- " + d.zone.to_s
            message = I18n.localize(datetime)
          end
          
        else
          # For other rules, refer to icecube
          begin
            message = @schedule.to_s
          rescue Exception
            locale = I18n.locale
            I18n.locale = :en
            message = @schedule.to_s
            I18n.locale = locale
          end
        end
        return message
      end

      def method_missing(meth, *args, &block)
        if @schedule.present? && @schedule.respond_to?(meth)
          @schedule.send(meth, *args, &block)
        end
      end

      def self.param_names
        [:id, :date, :time, :rule, :until, :count, :interval, day: [], day_of_week: [monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: []]]
      end
      
      def update_schedule
        puts "UPDATE SCHEDULE"
        if self.respond_to?('time_zone') 
          puts 'SAVE TIME ZONE' + Time.zone.now.zone
          self.time_zone = Time.zone.now.zone
        end
        date = self.date
        time = read_attribute(:time)
        datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, Time.zone.now.zone)
        puts "SAVE TIME: " + time.to_s + " ----> " + datetime.to_time.utc.to_s
        write_attribute(:time, datetime.to_time.utc)
      end
      
      def time(time = nil)
        if (time != nil)
          puts "WRITE ATTRIBUTE"
          write_attribute(:time, time)
          return
        end
        puts "READ ATTRIBUTE"
        time_zone = self.respond_to?('time_zone') ? self.send('time_zone') : Time.zone.now.zone
        saved_time = read_attribute(:time)
        if saved_time != nil
          tz_time = saved_time.in_time_zone(Time.zone)
          #tz_time = tz_time
          #datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time_zone)
          puts 'tz_time: ' + saved_time.to_s + " --- " + tz_time.to_s
          puts "@time: " + self.send('time_zone').to_s
          parsed_time = Time.parse(tz_time.strftime("%I:%M %p"))
          puts "parsed_time: " + parsed_time.to_s
          return parsed_time
        end
        time
      end

      def init_schedule()

        self.rule||= "singular"
        self.interval||= 1
        self.count||= 0
        
        db_time = read_attribute(:time)
        
        time = Date.today.to_time(:utc)
        if self.time.present?
          time = time + db_time.seconds_since_midnight.seconds
        end
        #time_string = time.strftime("%d-%m-%Y %I:%M %p")
        #time = Time.zone.parse(time_string)
        
        puts '***** INIT SCHEDULE'
        
        @schedule = IceCube::Schedule.new(time)

        if self.rule && self.rule != 'singular'

          interval = self.interval.present? ? self.interval.to_i : 1

          rule = IceCube::Rule.send("#{self.rule}", interval)

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