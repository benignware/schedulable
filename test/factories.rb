FactoryBot.define do
  
  factory :schedule do
    rule { 'weekly' }
    day { ['monday'] }
    time { Time.current + 1.hour }
    count { 10 }
    self.until { Time.current + 3.months }
  end
  
  factory :event do
    name { "My Event" }
    association :schedule
  end

  factory :event_occurrence do
    date { Time.current }
    schedulable { nil }
  end
end