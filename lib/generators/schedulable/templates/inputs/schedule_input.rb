class ScheduleInput < SimpleForm::Inputs::Base
  
  def input(wrapper_options)
    
    
    # I18n
    weekdays = Date::DAYNAMES.map(&:downcase)
    weekdays = weekdays.slice(1..7) << weekdays.slice(0)
    
    day_names = I18n.t('date.day_names', default: "")
    day_names = day_names.blank? ? weekdays.map { |day| day.capitalize } : day_names.slice(1..7) << day_names.slice(0)
    day_labels = Hash[weekdays.zip(day_names)]
    
    # Pass in default month names when missing in translations
    month_names = I18n.t('date.month_names', default: "")
    month_names = month_names.blank? ? Date::MONTHNAMES : month_names

    # Pass in default order when missing in translations
    date_order = I18n.t('date.order', default: "")
    date_order = date_order.blank? ? [:year, :month, :day] : date_order 
    
    date_options = {
      order: date_order,
      use_month_names: month_names
    }
    
    # Input html options
    input_html_options[:type] ||= input_type if html5?
    
    # Input options
    input_options[:interval] = !input_options[:interval].nil? ? input_options[:interval] : false
    input_options[:until] = !input_options[:until].nil? ? input_options[:until] : false
    input_options[:count] = !input_options[:count].nil? ? input_options[:count] : false

    @builder.simple_fields_for(:schedule, @builder.object.schedule || @builder.object.build_schedule) do |b|

      # Javascript element id
      field_id = b.object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"")
      
      b.template.content_tag("div", {id: field_id}) do
        
        b.input(:rule, collection: ['singular', 'daily', 'weekly', 'monthly'], label_method: lambda { |v| I18n.t("schedulable.rules.#{v}", default: v.capitalize) }, label: false, include_blank: false) << 
        
        template.content_tag("div", {data: {group: 'singular'}}) do
          b.input :date, date_options
        end <<
        
        template.content_tag("div", {data: {group: 'weekly'}}) do
          b.input :day, collection: weekdays, label_method: lambda { |v| ("&nbsp;" + day_labels[v]).html_safe}, boolean_style: :nested, as: :check_boxes
        end <<
        
        template.content_tag("div", {data: {group: 'monthly'}}) do
          
          b.simple_fields_for :day_of_week, OpenStruct.new(b.object.day_of_week || {}) do |db|
            template.content_tag("div", class: 'form-group' + (b.object.errors[:day_of_week].any? ? " has-error" : "")) do
              b.label(:day_of_week, error: true) << 
              template.content_tag("div", nil, style: 'min-width: 280px; display: table') do
                template.content_tag("div", nil, style: 'display: table-row') do
                  template.content_tag("span", nil, style: 'display: table-cell;') <<
                  ['1st', '2nd', '3rd', '4th', 'last'].reduce(''.html_safe) { | content, item | 
                    content << template.content_tag("span", I18n.t("schedulable.monthly_week_names.#{item}", default: item.to_s), style: 'display: table-cell; text-align: center')
                  }
                end <<
                weekdays.reduce(''.html_safe) do | content, weekday | 
                  content << template.content_tag("div", nil, style: 'display: table-row') do 
                    template.content_tag("span", day_labels[weekday] || weekday, style: 'display: table-cell') <<
                    db.collection_check_boxes(weekday.to_sym, [1, 2, 3, 4, -1], lambda { |i| i} , lambda { |i| "&nbsp;".html_safe}, checked: db.object.send(weekday), item_wrapper_tag: nil) do |cb|
                      template.content_tag("span", cb.check_box(), style: 'display: table-cell; text-align: center')
                    end 
                  end
                end
              end << 
              b.error(:day_of_week)
            end
          end
        end << 
        
        template.content_tag("div", data: {group: 'singular,daily,weekly,monthly'}) do
          b.input :time, date_options
        end << 
        
        (if input_options[:interval]
          template.content_tag("div", data: {group: 'daily,weekly,monthly'}) do
            b.input :interval
          end
        else
          b.input(:interval, as: :hidden, input_html: {value: 1})
        end) <<
        
        (if input_options[:until]
          template.content_tag("div", data: {group: 'daily,weekly,monthly'}) do
            b.input :until, date_options
          end
        else
          b.input(:until, as: :hidden, input_html: {value: nil})
        end) <<
        
        if input_options[:count]
          template.content_tag("div", data: {group: 'daily,weekly,monthly'}) do
            b.input :count
          end
        else
           b.input(:count, as: :hidden, input_html: {value: 0})
        end
        
        
        
      end <<
      
      template.javascript_tag(
        "(function() {" << 
        "  var container = document.querySelectorAll('##{field_id}'); container = container[container.length - 1]; " << 
        "  var select = container.querySelector(\"select[name*='rule']\"); " << 
        "  function update() {" <<
        "    var value = this.value;" << 
        "    [].slice.call(container.querySelectorAll(\"*[data-group]\")).forEach(function(elem) { " <<
        "      var groups = elem.getAttribute('data-group').split(',');" <<
        "      if (groups.indexOf(value) >= 0) {" <<
        "        elem.style.display = ''" << 
        "      } else {" <<
        "        elem.style.display = 'none'" << 
        "      }" <<
        "    });" <<
        "  }" << 
        "  if (jQuery) { jQuery(select).on('change', update); } else { select.addEventListener('change', update); }" <<
        "  update.call(select);" << 
        "})()"
      )
      
    end
    
    
  end
end