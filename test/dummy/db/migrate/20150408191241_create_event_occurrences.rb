class CreateEventOccurrences < ActiveRecord::Migration
  def change
    create_table :event_occurrences do |t|
      t.datetime :date
      t.references :schedulable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
