class ERBContext

  def initialize(hash)
    hash.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
  end

  def get_binding
    binding
  end

end

class String

  # Converts the string using eRuby
  def eruby(params={})
    params[:eruby_engine] == :erubis ? erubis(params) : erb(params)
  end

  # Converts the string using Erubis
  def erubis(params={})
    nanoc_require 'erubis'
    Erubis::Eruby.new(self).evaluate(params[:assigns] || {})
  end

  # Converts the string using ERB
  def erb(params={})
    nanoc_require 'erb'
    ERB.new(self).result(ERBContext.new(params[:assigns] || {}).get_binding)
  end

end

register_filter 'erb' do |page, pages, config|
  page.builtin.content.erb(:assigns => { :page => page, :pages => pages })
end

register_filter 'erubis' do |page, pages, config|
  page.builtin.content.erubis(:assigns => { :page => page, :pages => pages })
end

register_filter 'eruby' do |page, pages, config|
  $delayed_errors << "WARNING: The 'eruby' filter has been deprecated, and will be removed in 1.8." unless $quiet
  $delayed_errors << "         Please use the 'erb' or 'erubis' filters instead." unless $quiet
  assigns = { :page => page, :pages => pages }
  page.builtin.content.eruby(:assigns => assigns, :eruby_engine => config[:eruby_engine])
end
