schedulable
===========

Handling recurring events in rails

```
gem 'ice_cube'
```

```
rails g schedulable:install
```

```
rails g scaffold Event name:string
```


### Strong parameters
```
# app/controllers/event_controller.rb
def event_params
  params.require(:event).permit(:name, schedule_attributes: [:id, :date, :time, :rule, :until, :count, :interval, days: [], day_of_week: [monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: []]])
end
```

### SimpleForm
A custom input for simple_form is provided with the plugin

```
rails g schedulable:simple_form
```

```
-# app/views/events/_form.html.haml
.form-inputs
  = f.input :name
  = f.input :schedule, as: :schedule
```

### Event occurrences
```
rails g model EventOccurrence date:datetime
```

### Configuration
```
rails g schedulable:config
```


### Icecube
The schedulable plugin uses icecube for calculating occurrences. 
You can access icecube-methods via the schedule association:
```
puts @event.schedule.to_ical
```


