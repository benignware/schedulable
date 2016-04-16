schedulable
===========

> Handling recurring events in rails. 


## Install

Put the following into your Gemfile and run `bundle install`
```cli
gem 'ice_cube'
gem 'schedulable'
```

Install schedule migration and model
```cli
rails g schedulable:install
```

## Basic Usage

Create an event model
```cli
rails g scaffold Event name:string
```

Don't forget to migrate your database at this point in order to reflect the changes: `rake db:migrate`

Open `app/models/event.rb` and add the following to configure your model to be schedulable:

```ruby
# app/models/event.rb
class Event < ActiveRecord::Base
  acts_as_schedulable :schedule
end
```
This will add an association to the model named 'schedule' which holds the schedule information. 

### Schedule Model
The schedule-object respects the following attributes.
<table>
  <tr>
    <th>Name</th><th>Type</th><th>Description</th>
  </tr>
  <tr>
    <td>rule</td><td>String</td><td>One of 'singular', 'daily', 'weekly', 'monthly'</td>
  </tr>
  <tr>
    <td>date</td><td>Date</td><td>The date-attribute is used for singular events and also as startdate of the schedule</td>
  </tr>
  <tr>
    <td>time</td><td>Time</td><td>The time-attribute is used for singular events and also as starttime of the schedule</td>
  </tr>
  <tr>
    <td>day</td><td>Array</td><td>Day of week. An array of weekday-names, i.e. ['monday', 'wednesday']</td>
  </tr>
  <tr>
    <td>day_of_week</td><td>Hash</td><td>Day of nth week. A hash of weekday-names, containing arrays with indices, i.e. {:monday => [1, -1]} ('every first and last monday in month')</td>
  </tr>
  <tr>
    <td>interval</td><td>Integer</td><td>Specifies the interval of the recurring rule, i.e. every two weeks</td>
  </tr>
  <tr>
    <td>until</td><td>Date</td><td>Specifies the enddate of the schedule. Required for terminating events.</td>
  </tr>
  <tr>
    <td>count</td><td>Integer</td><td>Specifies the total number of occurrences. Required for terminating events.</td>
  </tr>
</table>

## Forms

Use schedulable's built-in helpers to setup your form.

### FormBuilder

Schedulable extends FormBuilder with a 'schedule_select'-helper and should therefore seamlessly integrate it with your existing views:

```erb
<%# app/views/events/_form.html.erb %>
<%= form_for(@event) do |f| %>

  <div class="field">
    <%= f.label :name %><br>
    <%= f.text_field :name %>
  </div>
  
  <div class="field">
    <%= f.label :schedule %><br>
    <%= f.schedule_select :schedule %>
  </div>
  
  <div class="actions">
    <%= f.submit %>
  </div>
<% end %>
```

#### Customize markup
You can customize the generated markup by providing a hash of html-attributes as `style`-option. For wrappers, also provide a `tag`-attribute.
* field_html
* input_html
* input_wrapper
* label_html
* label_wrapper
* number_field_html
* number_field_wrapper
* date_select_html
* date_select_wrapper
* collection_select_html
* collection_select_wrapper
* collection_check_boxes_item_html
* collection_check_boxes_item_wrapper

#### Integrate with Bootstrap

The schedulable-formhelper has built-in-support for Bootstrap. Simply point the style-option of schedule_input to `bootstrap` or set it as default in config. 

```erb
<%= f.schedule_select :schedule, style: :bootstrap %>
```

#### Custom inputs
Customize datetime-controls by passing FormBuilder-methods as a hash to the `input_types`-option. 
See below example for integrating [date_picker](https://github.com/benignware/date_picker) with schedulable:

```erb
<%# app/views/events/_form.html.erb %>
  
<div class="field form-group">
  <%= f.label :schedule %><br>
  <%= f.schedule_select :schedule, style: :bootstrap, until: true, input_types: {date: :date_picker, time: :time_picker, datetime: :datetime_picker} %>
</div>
```

#### Options

<table>
  <tr>
    <th>Name</th><th>Type</th><th>Description</th>
  </tr>
  <tr>
  <tr>
    <td>count</td><td>Boolean</td><td>Specifies whether to show 'count'-field</td>
  </tr>
  <tr>
    <td>input_types</td><td>Hash</td><td>Specify a hash containing custom form builder methods. Defaults to `{date: :date_select, time: :time_select, datetime: :datetime_select}`. The interface of the custom form builder method must either match `date_select` or `date_field`-methods</td>
  </tr>
  <tr>
    <td>interval</td><td>Boolean</td><td>Specifies whether to show 'interval'-field</td>
  </tr>
  <tr>
    <td>style</td><td>Hash</td><td>Specifies a hash of options to customize markup. By providing a string, you can point to a prefined set of options. Built-in styles are :bootstrap and :default.
  </tr>
  <tr>
    <td>until</td><td>Boolean</td><td>Specifies whether to show 'until'-field</td>
  </tr>
</table>

### SimpleForm
Also provided with the plugin is a custom input for simple_form. Make sure, you installed [SimpleForm](https://github.com/plataformatec/simple_form) and executed `rails generate simple_form:install`.


```cli
rails g schedulable:simple_form
```

```erb
<%# app/views/events/_form.html.erb %>
<%= simple_form_for(@event) do |f| %>
  
  <div class="field">
    <%= f.label :name %><br>
    <%= f.text_field :name %>
  </div>
  
  <div class="field">
    <%= f.label :schedule %><br>
    <%= f.input :schedule, as: :schedule %>
  </div>

  <div class="actions">
    <%= f.submit %>
  </div>
  
<% end %>
```

#### Integrate with Bootstrap

Simple Form has built-in support for Bootstrap as of version 3.0.0. 
At time of writing it requires some a little extra portion of configuration to make it look as expected:

```ruby
# config/initializers/simple_form_bootstrap.rb

# Inline date_select-wrapper for Bootstrap
config.wrappers :horizontal_select_date, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
  b.use :html5
  b.optional :readonly
  b.use :label, class: 'control-label'
  b.wrapper tag: 'div', class: 'form-inline' do |ba|
    ba.use :input, class: 'form-control'
    ba.use :error, wrap_with: { tag: 'span', class: 'help-block' }
    ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block' }
  end
end

# Include date_select-wrapper in mappings
config.wrapper_mappings = {
  datetime: :horizontal_select_date,
  date: :horizontal_select_date,
  time: :horizontal_select_date
}
```

#### Custom inputs

You can customize datetime-controls by passing simple_form-inputs as a hash to the `input_types`-option. See form helper for similar example 

For integrating [date_picker](https://github.com/benignware/date_picker) with schedulable and simple_form, you can also run date_picker's simple_form-generator to create a default `date_time`-input:
```cli
rails g date_picker:simple_form date_time
```

#### Options

<table>
  <tr>
    <th>Name</th><th>Type</th><th>Description</th>
  </tr>
  <tr>
  <tr>
    <td>count</td><td>Boolean</td><td>Specifies whether to show 'count'-field</td>
  </tr>
  <tr>
    <td>input_types</td><td>Hash</td><td>Specify a hash containing custom simple form inputs. Defaults to `{date: :date_time, time: :date_time, datetime: :date_time}`.</td>
  </tr>
  <tr>
    <td>interval</td><td>Boolean</td><td>Specifies whether to show 'interval'-field</td>
  </tr>
  <tr>
    <td>until</td><td>Boolean</td><td>Specifies whether to show 'until'-field</td>
  </tr>
</table>

### Sanitize parameters

Add schedule-attributes to the list of strong parameters in your controller:
```
# app/controllers/event_controller.rb
def event_params
  params.require(:event).permit(:name, schedule_attributes: Schedulable::ScheduleSupport.param_names)
end
```
Note: If you don't use `schedule` as attribute name, you need to rename `schedule_attributes` accordingly.


## Accessing IceCube
You can access ice_cube-methods directly via the schedule association:

```ruby
<%# app/views/events/show.html.erb %>
<p>
  <strong>Schedule:</strong>
  <%# Prints out a human-friendly description of the schedule, such as %> 
  <%= @event.schedule %>
</p>
```

```ruby
# Prints all occurrences of the event until one year from now
puts @event.schedule.occurrences(Time.now + 1.year)
# Export to ical
puts @event.schedule.to_ical
```
See [IceCube](https://github.com/seejohnrun/ice_cube) for more information.

## Internationalization

Schedulable is bundled with translations in english and german which will be automatically initialized with your app.
You can customize these messages by running the locale generator and edit the created yml-files:

```cli
rails g schedulable:locale de
```

### Date- and Time-Messages
Appropriate datetime translations should be included.
Basic setup for many languages can be found here:
[https://github.com/svenfuchs/rails-i18n/tree/master/rails/locale](https://github.com/svenfuchs/rails-i18n/tree/master/rails/locale).


### IceCube-Messages
An internationalization-branch of ice_cube can be found here: 
[https://github.com/joelmeyerhamme/ice_cube](https://github.com/joelmeyerhamme/ice_cube):

```ruby
gem 'ice_cube', git: 'git://github.com/joelmeyerhamme/ice_cube.git', branch: 'international' 
```

## Persist Occurrences

Schedulable allows for persisting occurrences and associate them with your event model. 
The Occurrence Model model must include an attribute of type 'datetime' with name 'date' as well as a polymorphic association to the schedulable event model.
Simply use the occurrence generator for setting up the appropriate model:

```ruby
rails g schedulable:occurrence EventOccurrence
```

On the other side, pass the association to your schedulable event model by using the `occurrences`-option of the `acts_as_schedulable`-method:


```ruby
# app/models/event.rb
class Event < ActiveRecord::Base
  acts_as_schedulable :schedule, occurrences: :event_occurrences
end
```

This will create the corresponding has_many-association and also add `remaining_event_occurrences` and `previous_event_occurrences`-methods.

Instances of remaining occurrences are persisted when the parent-model is saved.
Occurrences records will be reused if their datetime matches the saved schedule. 
Past occurrences stay untouched.

### Terminating and non-terminating events
An event is terminating if an until- or count-attribute has been specified. 
Since non-terminating events have infinite occurrences, we cannot build all occurrences at once ;-)
So we need to limit the number of occurrences in the database. 
By default this will be one year from now. 
This can be configured via the 'build_max_count' and 'build_max_period'-options. 
See notes on configuration. 

### Automate build of occurrences
Since we cannot build an infinite amount of occurrences, we will need a task that adds occurrences as time goes by. 
Schedulable comes with a rake-task that performs an update on all scheduled occurrences. 

```cli
rake schedulable:build_occurrences
```

You may add this task to crontab. 

#### Use 'whenever' to schedule the generation of occurrences

With the 'whenever' gem this can be easily achieved. 

```ruby
gem 'whenever', :require => false
```

Generate the 'whenever'-configuration file:

```cli
wheneverize .
```

Open up the file 'config/schedule.rb' and add the job:

```ruby
# config/schedule.rb
set :environment, "development"
set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 1.day do
  rake "schedulable:build_occurrences"
end
```

Write to crontab:

```cli
whenever -w
```

## Configuration
Generate the configuration file

```cli
rails g schedulable:config
```

Open 'config/initializers/schedulable.rb' and edit options as needed:

```ruby
Schedulable.configure do |config|
  # Build occurrences
  config.max_build_count = 0
  config.max_build_period = 1.year
  # SimpleForm
  config.simple_form = {
    input_types: {
   	  date: :date_time,
   	  time: :date_time,
   	  datetime: :date_time
    }
  }
  # Generic Form helper
  config.form_helper = {
    style: :default
  }
end
```


## Changelog
See the [Changelog](CHANGELOG.md) for recent enhancements, bugfixes and deprecations.
