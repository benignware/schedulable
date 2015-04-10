require Rails.root.join('../factories.rb')

if Rails.env != 'production'

  # ...

  # Users
  1.times do
    FactoryGirl.create :event
  end

  # ...

end