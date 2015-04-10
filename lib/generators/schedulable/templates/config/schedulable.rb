Schedulable.configure do |config|
  config.max_count = 0
  config.max_until = 1.year
  config.form_helper = {
    style: :default
  }
end