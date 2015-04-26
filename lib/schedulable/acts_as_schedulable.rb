module Schedulable
  
  module ActsAsSchedulable

    extend ActiveSupport::Concern
   
    included do
    end
   
    module ClassMethods
      
      def acts_as_schedulable(name, options = {})
        
        name||= :schedule
        attribute = :date
        
        has_one name, as: :schedulable, dependent: :destroy
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
          has_many remaining_occurrences_association, -> { where "#{occurrences_table_name}.date >= ?", Time.now}, remaining_occurrences_options
          
          # previous
          previous_occurrences_options = options[:occurrences].clone
          previous_occurrences_association = ("previous_" << occurrences_association.to_s).to_sym
          has_many previous_occurrences_association, -> { where "#{occurrences_table_name}.date < ?", Time.now}, previous_occurrences_options
          
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
        
          define_method "build_#{occurrences_association}" do 
            
            # build occurrences for events
            
            schedule = self.send(name)
            
            now = Time.now
            
            # TODO: Make configurable 
            occurrence_attribute = :date 
            
            schedulable = schedule.schedulable
            terminating = schedule.rule != 'singular' && (schedule.until.present? || schedule.count.present? && schedule.count > 1)
            
            max_period = Schedulable.config.max_build_period || 1.year
            max_date = now + max_period
            
            max_date = schedule.last.present? ? [max_date, schedule.last.to_time].min : max_date
            
            max_count = Schedulable.config.max_build_count || 100
            max_count = schedule.remaining_occurrences.present? && schedule.remaining_occurrences.any? ? [max_count, schedule.remaining_occurrences.count].min : max_count

            if schedule.rule != 'singular'
              
              # Get schedule occurrences
              all_occurrences = schedule.occurrences(max_date)
              occurrences = []
              # Filter future dates
              all_occurrences.each do |occurrence_date|
                if occurrence_date.present? && occurrence_date.to_time > now
                  occurrences << occurrence_date
                end
              end
            
            else
              singular_date_time = schedule.date.to_datetime + schedule.time.seconds_since_midnight.seconds
              occurrences = [singular_date_time]
            end
            
            # Build occurrences
            
            # Get existing records
            occurrences_records = schedulable.send(occurrences_association)

            # build occurrences
            existing_record = nil
            occurrences.each_with_index do |occurrence, index|
              
              # Pull an existing record
              existing_record = occurrences_records[index]
              
              if existing_record.present?
                # Overwrite existing record
                if !occurrences_records.update(existing_record.id, date: occurrence.to_datetime)
                  puts 'an error occurred while saving an existing occurrence record'
                end
              else
                # Create new record
                if !occurrences_records.create(date: occurrence.to_datetime)
                  puts 'an error occurred while creating an occurrence record'
                end
              end
            end
            
            
            # Clean up unused remaining occurrences 
            record_count = 0
            
            occurrences_records.each do |occurrence_record|
              if occurrence_record.date > now
                # Destroy occurrence if date or count lies beyond range
                
                if schedule.rule == 'singular' && record_count > 0 && (occurrence_record.date > max_date || max_count > 1 && record_count > max_count)
                  occurrences_records.destroy(occurrence_record)
                end
                record_count = record_count + 1
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
