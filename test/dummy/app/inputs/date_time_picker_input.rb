## app/inputs/date_time_picker_input.rb
require 'json'
class DateTimePickerInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    template.content_tag(:div, class: 'input-group date form_datetime', id: input_group_id) do
      template.concat span_table
      template.concat @builder.text_field(attribute_name, input_html_options)
      #template.concat span_remove
    end + javascript
  end

  def default_html_options
    {class: 'form-control', readonly: true, data: {language: I18n.locale}}
  end
  
  def input_html_options
    deep_merge({class: 'form-control', readonly: true, data: {language: I18n.locale, immediateUpdates: true}}, self.options[:input_html])
  end

  def span_remove
    template.content_tag(:span, class: 'input-group-addon addon') do
      template.concat icon_remove
    end
  end

  def span_table
    template.content_tag(:span, class: 'input-group-addon addon') do
      template.concat icon_table
    end
  end
  
  def input_group_id
    @builder.object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"") + "_" + attribute_name.to_s
  end
  
  
  
  def javascript
    puts 'jjjjjj' + input_html_options.to_s
    json = input_html_options[:data].to_json
    template.javascript_tag do
      (
      "(function($) {\n" <<
      "   $('##{input_group_id}').datetimepicker(\n#{json});\n" << 
      #"  $('##{input_group_id}').datetimepicker({\n" <<
      #"    language: '#{I18n.locale}',\n" <<
      #"    autoclose: true,\n" <<
      #"    todayBtn: true,\n" <<
      #"    pickerPosition: \"bottom-right\",\n" <<
      #"    format: 'mm-dd-yyyy hh:ii'\n" <<
      #"   });\n" <<
      "})(jQuery)\n"
      ).html_safe
    end
  end

  def icon_remove
    "<i class='glyphicon glyphicon-remove'></i>".html_safe
  end

  def icon_table
    "<i class='glyphicon glyphicon-th'></i>".html_safe
  end

  private
  
    def deep_merge(first, second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        first.merge(second, &merger)
    end
end