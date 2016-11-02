class AddTimeZoneToSchedules < ActiveRecord::Migration
  def change
    add_column :schedules, :time_zone, :string
  end
end
