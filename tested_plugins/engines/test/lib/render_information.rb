module RenderInformation
  def render_class_and_action(note = nil, options={})
    text = "rendered in #{self.class.name}##{params[:action]}"
    text += " (#{note})" unless note.nil?
    render options.update(plain: text)
  end
end