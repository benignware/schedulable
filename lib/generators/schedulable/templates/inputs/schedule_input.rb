class ScheduleInput < SimpleForm::Inputs::Base
  
  
  def input
    weekdays = Date::DAYNAMES.map(&:downcase)
    daynames = I18n.t('date.day_names')
    daylabels = Hash[weekdays.zip(daynames)]
    weekdays = weekdays.slice(1..7) << weekdays.slice(0)
      
    input_html_options[:type] ||= input_type if html5?
    
    # options
    input_options[:interval] = !input_options[:interval].nil? ? input_options[:interval] : true
    input_options[:until] = !input_options[:until].nil? ? input_options[:until] : true
    input_options[:count] = !input_options[:count].nil? ? input_options[:count] : true
    
    @builder.simple_fields_for(:schedule, @builder.object.schedule || @builder.object.build_schedule) do |b|
      
      b.template.content_tag("div", {id: b.object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"")}) do
        
        b.input(:rule, collection: ['singular', 'daily', 'weekly', 'monthly'], label_method: lambda { |i| I18n.t("schedulable.rules.#{i}") || i.capitalize }, label: false) << 
        
        template.content_tag("div", {data: {group: 'singular'}}) do
          b.input :date
        end <<
        
        template.content_tag("div", {data: {group: 'weekly'}}) do
          b.input :days, collection: weekdays, label_method: lambda { |v| ("&nbsp;" + daylabels[v]).html_safe}, as: :check_boxes
        end <<
        
        template.content_tag("div", {data: {group: 'monthly'}}) do
          
          b.simple_fields_for :day_of_week, OpenStruct.new(b.object.day_of_week || {}) do |db|
            template.content_tag("div", class: 'form-group' + (b.object.errors[:day_of_week].any? ? " has-error" : "")) do
              b.label(:day_of_week, error: true) << 
              template.content_tag("table", style: 'min-width: 280px') do
                template.content_tag("tr") do
                  template.content_tag("td") <<
                  ['1st', '2nd', '3rd', '4th', 'last'].reduce(''.html_safe) { | x, item | 
                    x << template.content_tag("td") do 
                       db.label(I18n.t("schedulable.monthly_week_names.#{item}") || item, required: false)
                    end
                  }
                end <<
                weekdays.reduce(''.html_safe) do | x, weekday | 
                  x << template.content_tag("tr") do 
                    template.content_tag("td") do
                      db.label daylabels[weekday] || weekday, required: false
                    end << 
                    db.collection_check_boxes(weekday.to_sym, [1, 2, 3, 4, -1], lambda { |i| i} , lambda { |i| "&nbsp;".html_safe}, item_wrapper_tag: :td, checked: db.object.send(weekday)) 
                  end
                end
              end <<
              b.error(:day_of_week)
            end
          end
        end << 
        
        template.content_tag("div", {data: {group: 'singular,daily,weekly,monthly'}}) do
          b.input :time
        end << 
        
        (template.content_tag("div", {data: {group: 'daily,weekly,monthly'}}) do
          b.input :interval
        end if input_options[:interval]) <<
        
        (template.content_tag("div", {data: {group: 'daily,weekly,monthly'}}) do
          b.input :until
        end if input_options[:until]) <<
        
        (template.content_tag("div", {data: {group: 'daily,weekly,monthly'}}) do
          b.input :count
        end if input_options[:count])
        
        
        
      end <<
      
      template.javascript_tag(
        "$(function() {" << 
        "  var container = $(\"*[id='#{b.object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"")}']\");" << 
        "  var select = container.find(\"select[name*='rule']\");" << 
        "  function update() {" <<
        "    var value = this.value;" << 
        "    container.find(\"*[data-group]\").each(function() {" <<
        "      var groups = $(this).data('group').split(',');" <<
        "      if ($.inArray(value, groups) >= 0) {" <<
        "        $(this).css('display', '');" << 
        "      } else {" <<
        "        $(this).css('display', 'none');" << 
        "      }" <<
        "    });" <<
        "  }" << 
        "  select.on('change', update);" <<
        "  update.call(select[0]);" << 
        "})"
      )
      
      
    end
    
    
  end
end