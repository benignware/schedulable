class DateTimeInput < SimpleForm::Inputs::Base
  
  def input(wrapper_options)
  
    # Determine control type
    if input_type == :date || input_type == :datetime || input_type == :time
      type = input_type
    else
      column = @builder.object.class.columns.select{ |c| c.name == attribute_name.to_s }.first
      type = column.present? ? column.type : nil
    end
    
    # Set default type
    type||= :date

    # Merge wrapper options
    opts = wrapper_options.merge(input_options.deep_dup)
    # Remove simple form specific attributes
    opts.except!(:as, :type, :min_max, :pattern);
    # Override type
    opts[:type] = type
    
    # Render date picker
    @builder.date_picker(attribute_name, opts)
    
  end
  
  
end