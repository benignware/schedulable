Schedulable.configure do |config|
  config.max_build_count = 0
  config.max_build_period = 1.year
  config.simple_form = {
    input_types: {
      #date: :date_picker, 
      #time: :date_picker,
      #datetime: :date_picker
    }
  }
  config.form_helper = {
    style: :bootstrap,
    input_types: {
      date: :date_picker,
      datetime: :datetime_picker,
      time: :time_picker
    }
  }
end