class EventOccurrence < ActiveRecord::Base
  belongs_to :schedulable, polymorphic: true
  default_scope lambda{order('date ASC')}
  scope :remaining, lambda{where(["date >= ?",DateTime.now])}
  scope :previous, lambda{where(["date < ?",DateTime.now])}
end
