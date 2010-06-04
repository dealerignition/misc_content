# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class TypedPagesExtension < Radiant::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/typed_pages"
  
  # define_routes do |map|
  #   map.connect 'admin/typed_pages/:action', :controller => 'admin/typed_pages'
  # end
  
  def activate
    # admin.tabs.add "Typed Pages", "/admin/typed_pages", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Typed Pages"
  end
  
end