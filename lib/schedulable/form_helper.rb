module Schedulable
  module FormHelper
    
    STYLES = {
      default: {
        field_html: {class: 'field'},
        input_wrapper: {tag: 'div'}
      },
      bootstrap: {
        field_html: {class: 'field form-group'},
        num_field_html: {class: 'form-control'},
        date_select_html: {class: 'form-control'},
        date_select_wrapper: {tag: 'div', class: 'form-inline'},
        collection_select_html: {class: 'form-control'},
        collection_check_boxes_item_wrapper: {tag: 'span', class: 'checkbox'}
      }
    }
    
    def self.included(base)
      ActionView::Helpers::FormBuilder.instance_eval do
        include FormBuilderMethods
      end
    end
    
    module FormBuilderMethods
      
      def schedule_select(attribute, input_options = {})

        template = @template

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
        date_order = I18n.t('date.order', default: [:year, :month, :day])
        date_order = date_order.map { |order|
          order.to_sym
        }
        
        # Setup date_options
        date_options = {
          order: date_order,
          use_month_names: month_names
        }
        
        # Get config options
        config_options = Schedulable.config.form_helper.present? ? Schedulable.config.form_helper : {style: :default}
        
        # Merge input options
        input_options = config_options.merge(input_options)
        
        # Setup input types
        input_types = {date: :date_select, time: :time_select, datetime: :datetime_select}.merge(input_options[:input_types] || {})
        
        # Setup style option
        if input_options[:style].is_a?(Symbol) || input_options[:style].is_a?(String)
          style_options = STYLES.has_key?(input_options[:style]) ? STYLES[input_options[:style]] : STYLES[:default]
        elsif input_options[:style].is_a?(Hash)
          style_options = input_options[:style]
        else
          style_options = STYLES[:default]
        end
        
        # Merge with input options
        style_options = style_options.merge(input_options)
        
        # Init style properties
        style_options[:field_html]||= {}
        
        style_options[:label_html]||= {}
        style_options[:label_wrapper]||= {}
        
        style_options[:input_html]||= {}
        style_options[:input_wrapper]||= {}
        
        style_options[:number_field_html]||= {}
        style_options[:number_field_wrapper]||= {}
        
        style_options[:date_select_html]||= {}
        style_options[:date_select_wrapper]||= {}
        
        style_options[:collection_select_html]||= {}
        style_options[:collection_select_wrapper]||= {}
        
        style_options[:collection_check_boxes_item_html]||= {}
        style_options[:collection_check_boxes_item_wrapper]||= {}
        
        # Merge with default input selector
        style_options[:number_field_html] = style_options[:input_html].merge(style_options[:number_field_html])
        style_options[:number_field_wrapper] = style_options[:input_wrapper].merge(style_options[:number_field_wrapper])
        
        style_options[:date_select_html] = style_options[:input_html].merge(style_options[:date_select_html])
        style_options[:date_select_wrapper] = style_options[:input_wrapper].merge(style_options[:date_select_wrapper])
        
        style_options[:collection_select_html] = style_options[:input_html].merge(style_options[:collection_select_html])
        style_options[:collection_select_wrapper] = style_options[:input_wrapper].merge(style_options[:collection_select_wrapper])
        
        style_options[:collection_check_boxes_item_html] = style_options[:input_html].merge(style_options[:collection_check_boxes_item_html])
        style_options[:collection_check_boxes_item_wrapper] = style_options[:input_wrapper].merge(style_options[:collection_check_boxes_item_wrapper])
        
        # Here comes the logic...
        
        # Javascript element id
        field_id = @object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"") + "_" + attribute.to_s

        @template.content_tag("div", {id: field_id}) do
          
          self.fields_for(attribute, @object.send(attribute.to_s) || @object.send("build_" + attribute.to_s)) do |f|
          
            # Rule Select
            @template.content_tag("div", style_options[:field_html]) do
              select_output = f.collection_select(:rule, ['singular', 'daily', 'weekly', 'monthly'], lambda { |v| return v}, lambda { |v| I18n.t("schedulable.rules.#{v}", default: v.capitalize) }, {include_blank: false}, style_options[:collection_select_html])
              content_wrap(@template, select_output, style_options[:collection_select_wrapper])
            end <<
            
            
            # Date Select
            @template.content_tag("div", style_options[:field_html].merge({data: {group: input_options[:from] ? 'singular,daily,weekly,monthly' : 'singular'}})) do
              content_wrap(@template, f.label(:date, style_options[:label_html].merge({ data: {group: 'singular'}})) << f.label(:start_date, style_options[:label_html].merge({ data: {group: 'daily,weekly,monthly'}})), style_options[:label_wrapper]) <<
              content_wrap(@template, f.send(input_types[:date].to_sym, *[:date].concat(f.method(input_types[:date].to_sym).parameters.count >= 3 ? [date_options] : []).concat([style_options[:date_select_html].clone])), style_options[:date_select_wrapper])
            end << 
            
            # Weekly Checkboxes
            @template.content_tag("div", style_options[:field_html].merge({data: {group: 'weekly'}})) do
              content_wrap(@template, f.label(:day), style_options[:label_wrapper]) <<
              f.collection_check_boxes(:day, weekdays, lambda { |v| return v}, lambda { |v| ("&nbsp;" + day_labels[v]).html_safe}) do |cb|
                check_box_output = cb.check_box(style_options[:collection_check_boxes_item_html])
                text = cb.text
                nested_output = cb.label({}) do |l|
                  check_box_output + text
                end
                content_wrap(@template, nested_output, style_options[:collection_check_boxes_item_wrapper])
              end
            end << 
            
            # Monthly Checkboxes
            @template.content_tag("div", style_options[:field_html].merge({data: {group: 'monthly'}})) do
              f.fields_for :day_of_week, OpenStruct.new(f.object.day_of_week || {}) do |db|
                content_wrap(@template, f.label(:day_of_week), style_options[:label_wrapper]) <<
                @template.content_tag("div", nil, style: 'min-width: 280px; display: table') do
                  @template.content_tag("div", nil, style: 'display: table-row') do
                    @template.content_tag("span", nil, style: 'display: table-cell;') <<
                    ['1st', '2nd', '3rd', '4th', 'last'].reduce(''.html_safe) { | content, item | 
                      content << @template.content_tag("span", I18n.t("schedulable.monthly_week_names.#{item}", default: item.to_s), style: 'display: table-cell; text-align: center')
                    }
                  end <<
                  weekdays.reduce(''.html_safe) do | content, weekday | 
                    content << @template.content_tag("div", nil, style: 'display: table-row') do 
                      @template.content_tag("span", day_labels[weekday] || weekday, style: 'display: table-cell') <<
                      db.collection_check_boxes(weekday.to_sym, [1, 2, 3, 4, -1], lambda { |i| i} , lambda { |i| "&nbsp;".html_safe}, checked: db.object.send(weekday)) do |cb|
                        @template.content_tag("span", style: 'display: table-cell; text-align: center') { cb.check_box() }
                      end 
                    end
                  end
                end
              end
            end <<
            
            # Time Select
            @template.content_tag("div", style_options[:field_html].merge({data: {group: 'singular,daily,weekly,monthly'}})) do
              content_wrap(@template, f.label(:time, style_options[:label_html]), style_options[:label_wrapper]) <<
              content_wrap(@template, f.send(input_types[:time].to_sym, *[:time].concat(f.method(input_types[:time].to_sym).parameters.count >= 3 ? [date_options] : []).concat([style_options[:date_select_html].clone])), style_options[:date_select_wrapper])
            end <<
            
            # Optional Fields...
            
            # Interval Number Field
            (if input_options[:interval]
            
              @template.content_tag("div", style_options[:field_html].merge({data: {group: 'daily,weekly,monthly'}})) do
                content_wrap(@template, f.label(:interval, style_options[:label_html]), style_options[:label_wrapper]) <<
                content_wrap(@template, f.number_field(:interval, style_options[:number_field_html]), style_options[:number_field_wrapper])
              end
            else
              f.hidden_field(:interval, value: 1)
            end) <<
            
             # Until Date Time Select
            (if input_options[:until]
             
              @template.content_tag("div", style_options[:field_html].merge({data: {group: 'daily,weekly,monthly'}})) do
                content_wrap(@template, f.label(:until, style_options[:label_html]), style_options[:label_wrapper]) <<
                content_wrap(@template, f.send(input_types[:datetime].to_sym, *[:until].concat(f.method(input_types[:datetime].to_sym).parameters.count >= 3 ? [date_options] : []).concat([style_options[:date_select_html].clone])), style_options[:date_select_wrapper])
              end
            else
              f.hidden_field(:until, value: nil)
            end) <<
            
            # Count Number Field
            if input_options[:count]
              @template.content_tag("div", style_options[:field_html].merge({data: {group: 'daily,weekly,monthly'}})) do
                content_wrap(@template, f.label(:count, style_options[:label_html]), style_options[:label_wrapper]) <<
                content_wrap(@template, f.number_field(:count, style_options[:number_field_html]), style_options[:number_field_wrapper])
              end
            else
               f.hidden_field(:count, value: 0)
            end
            
          end
          
        end <<
        
        # Javascript
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
          "  if (typeof jQuery !== 'undefined') { jQuery(select).on('change', update); } else { select.addEventListener('change', update); }" <<
          "  update.call(select);" << 
          "})()"
        )
        
      end
      
      
      private 
        def content_wrap(template, content, options = nil)
          if options.present? && options.has_key?(:tag)
            template.content_tag(options[:tag], content, options.except(:tag))
          else
            content
          end  
        end
      
    end
    
    
  end
end