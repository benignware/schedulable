schedulable
===========

Handling recurring events in rails. 


The schedulable plugin depends on the ice_cube scheduling-library:
```
gem 'ice_cube'
```

Install schedule migration and model
```
rails g schedulable:install
```

### Usage

Create your event model
```
rails g scaffold Event name:string
```

Configure your model to be schedulable:
```
# app/models/event.rb
class Event < ActiveRecord::Base
  acts_as_schedulable
end
```
This will add an association named 'schedule' that holds the schedule information. 

#### SimpleForm
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

#### Strong parameters
```
# app/controllers/event_controller.rb
def event_params
  params.require(:event).permit(:name, schedule_attributes: Schedulable::ScheduleSupport.param_names)
end
```

### IceCube
The schedulable plugin uses ice_cube for calculating occurrences. 
You can access ice_cube-methods via the schedule association:
```
# prints all occurrences of the event until one year from now
puts @event.schedule.occurrences(Time.now + 1.year)
# export to ical
puts @event.schedule.to_ical
```
See https://github.com/seejohnrun/ice_cube for more information.

### Event occurrences
We need to have the occurrences persisted because we want to query the database for all occurrences of the event model or need to add additional attributes and functionality, such as allowing users to attend to a specific occurrence of an event.
The schedulable gem handles this for you. 
Your occurrence model must include an attribute of type 'datetime' with name 'date' as well as a reference to your event model to setup up the association properly:  

```
rails g model EventOccurrence event_id:integer date:datetime
```

```
# app/models/event_occurrence.rb
class EventOccurrence < ActiveRecord::Base
  belongs_to :event
end
```

Then you can simply declare your occurrences with the acts_as_schedule-method like this:
```
# app/models/event.rb
class Event < ActiveRecord::Base
  acts_as_schedulable occurrences: :event_occurrences
end
```
This will add a has_many-association with the name 'event_occurences' to your event-model. 
Instances of occurrences are built when the schedule is saved.

#### Terminating and non-terminating events
An event is terminating if an until- or count-attribute has been specified. 
Since non-terminating events have infinite occurrences, we cannot build all occurrences at once ;-)
So we need to limit the number of occurrences in the database. 
By default this will be one year from now. 
This can be configured via the 'build_max_count' and 'build_max_period'-options. 
See notes on configuration. 

#### Automate building of occurrences
Since we cannot build all occurrences at once, we will need a task that adds occurrences as time goes by. 
Schedulable comes with a rake-task that performs an update on all scheduled occurrences. 
```
rake schedulable:build_occurrences
```
You may add the task to crontab. 
With the 'whenever' gem this can be easily achieved. 
```
gem 'whenever', :require => false
```
Create the 'whenever'-configuration file:
```
wheneverize .
```
Open up the file 'config/schedule.rb' and add the job:
```
set :environment, "development"
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 1.day do
  rake "schedulable:build_occurrences"
end
```


### Configuration
Generate the configuration file
```
rails g schedulable:config
```
Open 'config/initializers/schedulable.rb' and edit options as you need:
```
Schedulable.configure do |config|
  config.max_build_count = 0
  config.max_build_period = 1.year
end
```










