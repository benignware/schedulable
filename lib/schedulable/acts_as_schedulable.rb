module Schedulable
  
  module ActsAsSchedulable

    extend ActiveSupport::Concern
   
    included do
    end
   
    module ClassMethods
      
      def acts_as_schedulable(name = :schedule, *args, **kwargs)
        name = name.to_sym
        options = {}
        options = args.last if args.last.is_a?(Hash)
        options = options.merge(kwargs) if kwargs.any?
        
        has_one name,
                -> { where(schedulable_type: base_class.name) },
                as: :schedulable,
                dependent: :destroy,
                class_name: 'Schedulable::Model::Schedule'
        accepts_nested_attributes_for name
        
        if options[:occurrences]
          
          # setup association
          occurrences_association = if options[:occurrences].is_a?(String) || options[:occurrences].is_a?(Symbol)
            options[:occurrences].to_sym
          else
            options[:occurrences][:name]
          end
          
          occurrences_options = options[:occurrences].is_a?(Hash) ? options[:occurrences].except(:name) : {}
          occurrences_options[:class_name] = occurrences_association.to_s.classify
          occurrences_options[:as] ||= :schedulable
          occurrences_options[:dependent] ||= :destroy
          occurrences_options[:autosave] ||= true
          
          has_many occurrences_association,
                   -> { where(schedulable_type: base_class.name) },
                   **occurrences_options
          
          # table_name
          occurrences_table_name = occurrences_association.to_s.tableize
          
          # remaining
          remaining_occurrences_options = occurrences_options.clone
          remaining_occurrences_association = ("remaining_" << occurrences_association.to_s).to_sym
          has_many remaining_occurrences_association,
                   -> { where("#{occurrences_table_name}.date >= ? AND schedulable_type = ?", Time.current, base_class.name).order('date ASC') },
                   **remaining_occurrences_options
          
          # previous
          previous_occurrences_options = occurrences_options.clone
          previous_occurrences_association = ("previous_" << occurrences_association.to_s).to_sym
          has_many previous_occurrences_association,
                   -> { where("#{occurrences_table_name}.date < ? AND schedulable_type = ?", Time.current, base_class.name).order('date DESC')},
                   **previous_occurrences_options
          
          ActsAsSchedulable.add_occurrences_association(self, occurrences_association)
          
          after_save :"build_#{occurrences_association}"
 
          singleton_class.define_method("build_#{occurrences_association}") do 
            # build occurrences for all events
            schedulables = all
            schedulables.each do |schedulable| 
              schedulable.send("build_#{occurrences_association}")
            end
          end
        
          define_method "build_#{occurrences_association}_after_update" do 
            schedule = send(name)
            if schedule.saved_changes.any?
              send("build_#{occurrences_association}")
            end
          end
        
          define_method "build_#{occurrences_association}" do 
            schedule = send(name)
            
            if schedule.present?
              now = Time.current
              
              schedulable = schedule.schedulable
              terminating = schedule.rule != 'singular' && (schedule.until.present? || schedule.count.present? && schedule.count > 1)
              
              max_period = Schedulable.config.max_build_period || 1.year
              max_date = now + max_period
              
              if terminating && schedule.last.respond_to?(:to_time)
                max_date = [max_date, schedule.last.to_time].min
              end
              
              max_count = Schedulable.config.max_build_count || 100
              max_count = terminating && schedule.remaining_occurrences.any? ? [max_count, schedule.remaining_occurrences.count].min : max_count
  
              occurrences = if schedule.rule != 'singular'
                # Get schedule occurrences
                all_occurrences = schedule.occurrences_between(Time.current, max_date.to_time)
                # Filter valid dates
                all_occurrences.select.with_index do |occurrence_date, index|
                  occurrence_date.present? && 
                    occurrence_date.to_time > now && 
                    occurrence_date.to_time < max_date && 
                    (index <= max_count || max_count <= 0)
                end
              else
                # Get Singular occurrence
                d = schedule.date
                t = schedule.time
                [(d + t.seconds_since_midnight.seconds).to_datetime]
              end
  
              # Build occurrences
              update_mode = Schedulable.config.update_mode || :datetime
              
              # Always use index as base for singular events
              update_mode = :index if schedule.rule == 'singular'
              
              # Get existing remaining records
              occurrences_records = schedulable.send("remaining_#{occurrences_association}")
  
              # build occurrences
              occurrences.each_with_index do |occurrence, index|
                # Pull existing records
                existing_records = case update_mode
                when :index
                  [occurrences_records[index]]
                when :datetime
                  occurrences_records.select { |record| record.date.to_datetime == occurrence.to_datetime }
                else
                  []
                end
  
                if existing_records.any?
                  # Update existing records
                  existing_records.each do |existing_record|
                    unless existing_record.update(date: occurrence.to_datetime)
                      Rails.logger.error('An error occurred while saving an existing occurrence record')
                    end
                  end
                else
                  # Create new record
                  unless occurrences_records.create(date: occurrence.to_datetime)
                    Rails.logger.error('An error occurred while creating an occurrence record')
                  end
                end
              end
              
              # Clean up unused remaining occurrences 
              occurrences_records.reload.each.with_index do |occurrence_record, index|
                if occurrence_record.date > now
                  # Destroy occurrence if date or count lies beyond range
                  if schedule.rule != 'singular' && 
                     (!schedule.occurs_on?(occurrence_record.date.to_date) || 
                      !schedule.occurring_at?(occurrence_record.date.to_time) || 
                      occurrence_record.date > max_date) || 
                     (schedule.rule == 'singular' && index > 0)
                    occurrence_record.destroy
                  end
                end
              end
            end
          end
        end
      end
    end
    
    def self.occurrences_associations_for(clazz)
      @@schedulable_occurrences ||= []
      @@schedulable_occurrences.select { |item|
        item[:class] == clazz
      }.map { |item|
        item[:name]
      }
    end
    
    private
    
    def self.add_occurrences_association(clazz, name)
      @@schedulable_occurrences ||= []
      @@schedulable_occurrences << {class: clazz, name: name}
    end
  end
end

