require 'rake'
desc 'Builds occurrences for schedulable models'
namespace :schedulable do
  task :build_occurrences => :environment do
    Schedule.uniq.pluck(:schedulable_type).each do |schedule|
      clazz = schedule.schedulable.class
      occurrences_associations = Schedulable::ActsAsSchedulable.occurrences_associations_for(clazz)
      occurrences_associations.each do |association|
        clazz.send("build_" + association.to_s)
      end
    end
  end
end