module Schedulable
  
  module ActsAsSchedulable

    extend ActiveSupport::Concern
   
    included do
    end
   
    module ClassMethods
      
      def acts_as_schedulable(options = {})
        
        name = options[:name] || :schedule
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
              puts "build occurrences for #{schedulables.length} #{self.name.tableize}" 
              schedulables.each do |schedulable| 
                schedulable.send("build_#{occurrences_association}")
              end
            end
          end
        
          define_method "build_#{occurrences_association}" do 
            
            # build occurrences for events
            
            schedule = self.send(name)
            
            now = Time.now
            occurrence_attribute = :date
            
            schedulable = schedule.schedulable
            terminating = schedule.until.present? || schedule.count.present? && schedule.count > 0

            max_build_period = Schedulable.config.max_build_period || 1.year
            max_date = now + max_build_period
            max_date = terminating ? [max_date, schedule.last.to_time].min : max_date
            
            max_build_count = Schedulable.config.max_build_count || 0
            max_build_count = terminating ? [max_build_count, schedule.remaining_occurrences.count].min : max_build_count

            # get occurrences
            if max_build_count > 0
              # get next occurrences for max_build_count
              occurrences = schedule.next_occurrences(max_build_count)
            end
            
            if !occurrences || occurrences.last && occurrences.last.to_time > max_date 
              # get next occurrences for max_date
              all_occurrences = schedule.occurrences(max_date)
              occurrences = []
              # filter future dates
              all_occurrences.each do |occurrence_date|
                if occurrence_date.to_time > now
                  occurrences << occurrence_date
                end
              end
            end
            
            
            puts 'build occurrences'

            # build occurrences
            assocs = schedulable.class.reflect_on_all_associations(:has_many)
            assocs.each do |assoc|
              puts assoc.name
            end
            
            occurrences_records = schedulable.send(occurrences_association)
            
            # clean up unused remaining occurrences 
            record_count = 0
            occurrences_records.each do |occurrence_record|
              if occurrence_record.date > now
                # destroy occurrence if it's not used anymore
                if !schedule.occurs_on?(occurrence_record.date) || occurrence_record.date > max_date || record_count > max_build_count
                  if occurrences_records.destroy(occurrence_record)
                    puts 'an error occurred while destroying an unused occurrence record'
                  end
                end
                record_count = record_count + 1
              end
            end
            
            # build occurrences
            occurrences.each do |occurrence|
              
              # filter existing occurrence records
              existing = occurrences_records.select { |record|
                record.date.to_date == occurrence.to_date
              }
              if existing.length > 0
                # a record for this date already exists, adjust time
                existing.each { |record|
                  #record.date = occurrence.to_datetime
                  if !occurrences_records.update(record, date: occurrence.to_datetime)
                    puts 'an error occurred while saving an existing occurrence record'
                  end
                }
              else
                # create new record
                if !occurrences_records.create(date: occurrence.to_datetime)
                  puts 'an error occurred while creating an occurrence record'
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
