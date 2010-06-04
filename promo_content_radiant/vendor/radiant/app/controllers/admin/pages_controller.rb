class Admin::PagesController < Admin::ResourceController
  before_filter :initialize_meta_rows_and_buttons, :only => [:new, :edit, :create, :update]

  responses do |r|
    r.plural.html { render }
    r.plural.js do
      @level = params[:level].to_i
      @template_name = 'index'
      response.headers['Content-Type'] = 'text/html;charset=utf-8'
      render :action => 'children.html.haml', :layout => false
    end
    r.plural.xml { render :xml => @homepage.children.to_xml }
  end
  
  def index
    @homepage = Page.find_by_parent_id(nil)
    response_for :plural
  end

  def new
    self.model = model_class.new_with_defaults(config)
    if params[:page_id].blank?
      self.model.slug = '/'
    end
    self.model.page_type = params[:page_type]
    
    response_for :singular
  end
  
  def create
    model.update_attributes!(params[model_symbol])
    announce_saved("The #{model.page_type.to_s.capitalize} was created.")
    model.create_children_for_page_type
    response_for :create
  end               
  
  private
    def model_class
      if params[:page_id]
        Page.find(params[:page_id]).children
      else
        Page
      end
    end

    def announce_saved(message = nil)
      flash[:notice] = message || "Your page has been saved below."
    end

    def announce_pages_removed(count)
      flash[:notice] = if count > 1
        "The pages were successfully removed from the site."
      else
        "The page was successfully removed from the site."
      end
    end

    def initialize_meta_rows_and_buttons
      @buttons_partials ||= []
      @meta ||= []
      @meta << {:field => "slug", :type => "text_field", :args => [{:class => 'textbox', :maxlength => 100}]}
      @meta << {:field => "breadcrumb", :type => "text_field", :args => [{:class => 'textbox', :maxlength => 160}]}
      @meta << {:field => "description", :type => "text_field", :args => [{:class => 'textbox', :maxlength => 200}]}
      @meta << {:field => "keywords", :type => "text_field", :args => [{:class => 'textbox', :maxlength => 200}]}
    end

end
