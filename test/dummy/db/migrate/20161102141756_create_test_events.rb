class CreateTestEvents < ActiveRecord::Migration
  def change
    create_table :test_events do |t|
      t.date :date
      t.time :time

      t.timestamps null: false
    end
  end
end
