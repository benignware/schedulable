class DatePickerInput < SimpleForm::Inputs::Base
  
  def input(wrapper_options)
  
    if input_type == :date || input_type == :datetime || input_type == :time
      type = input_type
    else
      column = @builder.object.class.columns.select{ |c| c.name == attribute_name.to_s }.first
      type = column.present? ? column.type : nil
    end
    
    type||= :date

    opts = wrapper_options.merge(input_options.deep_dup)
    opts[:type] = type
    
    @builder.date_picker(attribute_name, opts)
    
  end
  
  
end