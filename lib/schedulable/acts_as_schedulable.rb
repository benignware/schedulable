module Schedulable
  
  module ActsAsSchedulable

    extend ActiveSupport::Concern
   
    included do
    end
   
    module ClassMethods
      
      def acts_as_schedulable(name, options = {})
        
        name||= :schedule
        attribute = :date
        
        has_one name, as: :schedulable, dependent: :destroy, class_name: 'Schedule'
        accepts_nested_attributes_for name
        
        if options[:occurrences]
          
          # setup association
          if options[:occurrences].is_a?(String) || options[:occurrences].is_a?(Symbol)
            occurrences_association = options[:occurrences].to_sym
            options[:occurrences] = {}
          else
            occurrences_association = options[:occurrences][:name]
            options[:occurrences].delete(:name)
          end
          options[:occurrences][:class_name] = occurrences_association.to_s.classify
          options[:occurrences][:as]||= :schedulable
          options[:occurrences][:dependent]||:destroy
          options[:occurrences][:autosave]||= true
          
          has_many occurrences_association, options[:occurrences]
          
          # table_name
          occurrences_table_name = occurrences_association.to_s.tableize
          
          # remaining
          remaining_occurrences_options = options[:occurrences].clone
          remaining_occurrences_association = ("remaining_" << occurrences_association.to_s).to_sym
          has_many remaining_occurrences_association, -> { where("#{occurrences_table_name}.date >= ?", Time.now).order('date ASC') }, remaining_occurrences_options
          
          # previous
          previous_occurrences_options = options[:occurrences].clone
          previous_occurrences_association = ("previous_" << occurrences_association.to_s).to_sym
          has_many previous_occurrences_association, -> { where("#{occurrences_table_name}.date < ?", Time.now).order('date DESC')}, previous_occurrences_options
          
          ActsAsSchedulable.add_occurrences_association(self, occurrences_association)
          
          after_save "build_#{occurrences_association}"
 
          self.class.instance_eval do
            define_method("build_#{occurrences_association}") do 
              # build occurrences for all events
              # TODO: only invalid events
              schedulables = self.all
              schedulables.each do |schedulable| 
                schedulable.send("build_#{occurrences_association}")
              end
            end
          end
        
          define_method "build_#{occurrences_association}_after_update" do 
            schedule = self.send(name)
            if schedule.changes.any?
              self.send("build_#{occurrences_association}")
            end
          end
        
          define_method "build_#{occurrences_association}" do 
            
            # build occurrences for events
            
            schedule = self.send(name)
            
            if schedule.present?
            
              now = Time.now
              
              # TODO: Make configurable 
              occurrence_attribute = :date 
              
              schedulable = schedule.schedulable
              terminating = schedule.rule != 'singular' && (schedule.until.present? || schedule.count.present? && schedule.count > 1)
              
              max_period = Schedulable.config.max_build_period || 1.year
              max_date = now + max_period
              
              max_date = terminating ? [max_date, schedule.last.to_time].min : max_date
              
              max_count = Schedulable.config.max_build_count || 100
              max_count = terminating && schedule.remaining_occurrences.any? ? [max_count, schedule.remaining_occurrences.count].min : max_count
  
              if schedule.rule != 'singular'
                # Get schedule occurrences
                all_occurrences = schedule.occurrences_between(Time.now, max_date.to_time)
                occurrences = []
                # Filter valid dates
                all_occurrences.each_with_index do |occurrence_date, index|
                  if occurrence_date.present? && occurrence_date.to_time > now
                    if occurrence_date.to_time < max_date && (index <= max_count || max_count <= 0)
                      occurrences << occurrence_date
                    else
                      max_date = [max_date, occurrence_date].min
                    end
                  end
                end
              else
                # Get Singular occurrence
                date = schedule.date
                time = schedule.time
                puts "CNVERT: " + date.to_s + ", " + time.to_s
                datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, Time.zone.now.zone)
                #datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec)
                time_zone = schedule.respond_to?(:time_zone) ? schedule.time_zone : Time.zone.now.zone.to_s
                puts 'time_zone: ' + time_zone.to_s
                puts 'schedule time_zone: ' + schedule.time_zone.to_s
                #datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, 'Etc/UTC')
                #datetime = (date + time.seconds_since_midnight.seconds).to_datetime
                puts "RESULT " + datetime.to_s
                occurrences = [datetime]
              end
  
              # Build occurrences
              update_mode = Schedulable.config.update_mode || :datetime
              
              # Always use index as base for singular events
              if schedule.rule == 'singular'
                update_mode = :index
              end
              
              # Get existing remaining records
              occurrences_records = schedulable.send("remaining_#{occurrences_association}")
              
              puts '---->' + occurrences.to_s
  
              # build occurrences
              existing_record = nil
              occurrences.each_with_index do |occurrence, index|
                
                # Pull an existing record
                if update_mode == :index
                  existing_records = [occurrences_records[index]]
                elsif update_mode == :datetime
                  existing_records = occurrences_records.select { |record|
                    record.date.to_datetime == occurrence.to_datetime
                  }
                else
                  existing_records = []
                end
  
                if existing_records.any?
                  # Overwrite existing records
                  existing_records.each do |existing_record|
                    if !occurrences_records.update(existing_record.id, date: occurrence.to_datetime)
                      puts 'An error occurred while saving an existing occurrence record'
                    end
                  end
                else
                  # Create new record
                  puts 'INSERT: ' + occurrence.to_s + " --- " + occurrence.to_datetime.to_s
                  if !occurrences_records.create(date: occurrence.to_datetime)
                    puts 'An error occurred while creating an occurrence record'
                  end
                end
              end
              
              
              # Clean up unused remaining occurrences 
              occurrences_records = schedulable.send("remaining_#{occurrences_association}")
              record_count = 0
              occurrences_records.each do |occurrence_record|
                if occurrence_record.date > now
                  # Destroy occurrence if date or count lies beyond range
                  if schedule.rule != 'singular' && (!schedule.occurs_on?(occurrence_record.date.to_date) || !schedule.occurring_at?(occurrence_record.date.to_time) || occurrence_record.date > max_date) || schedule.rule == 'singular' && record_count > 0
                    occurrences_records.destroy(occurrence_record)
                  end
                  record_count = record_count + 1
                end
              end
            end
          end
        end
      end
    end
    
    def self.occurrences_associations_for(clazz)
      @@schedulable_occurrences||= []
      @@schedulable_occurrences.select { |item|
        item[:class] == clazz
      }.map { |item|
        item[:name]
      }
    end
    
    private
    
    def self.add_occurrences_association(clazz, name)
      @@schedulable_occurrences||= []
      @@schedulable_occurrences << {class: clazz, name: name}
    end
    
      
  end
end  
ActiveRecord::Base.send :include, Schedulable::ActsAsSchedulable
