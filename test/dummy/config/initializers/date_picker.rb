DatePicker.configure do |config|
  config.style = :none
  config.formats = {
    date: :default,
    datetime: :default,
    time: :only_time
  }
end