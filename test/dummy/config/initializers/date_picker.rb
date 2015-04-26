DatePicker.configure do |config|
  config.style = :bootstrap
  config.formats = {
    date: :default,
    datetime: :default,
    time: :only_time
  }
end