DatePicker.configure do |config|
  config.style = :flatpickr
  config.formats = {
    date: :default,
    datetime: :default,
    time: :only_time
  }
end