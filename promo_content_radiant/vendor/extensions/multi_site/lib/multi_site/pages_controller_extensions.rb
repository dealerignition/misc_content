module MultiSite::PagesControllerExtensions
  def self.included(base)
    base.class_eval {
      before_filter :set_site, :only => [:remove, :new, :edit]
      around_filter :scope_layouts_to_site, :only => [:new, :edit]

      alias_method_chain :index, :root
      %w{edit new remove continue_url clear_model_cache}.each do |m|
        alias_method_chain m.to_sym, :site
      end
    }
  end

  def index_with_root
    cookies.delete('expanded_rows')
    if user_developer? # or admin
      if params[:root] # If a root page is specified (should this ever be required for non-developers?)
        @homepage = Page.find(params[:root])
        @site = @homepage.root.site
      elsif session[:site]
        @site = Site.find(session[:site])
        @homepage = @site.homepage if @site.homepage
      elsif (@site = Site.find(:first, :order => "position ASC")) && @site.homepage # If there is a site defined
        @homepage = @site.homepage
      end
      
      if !@homepage
        index_without_root
        return
      end
    elsif (@site = current_user.site) && @site.homepage
      @homepage = @site.homepage
    else
      access_denied
      return
    end
    
    session[:site] = @site.id if @site

    response_for :plural
  end

  def remove_with_site
    if user_authorized?
      if request.post?
        announce_pages_removed(@page.children.count + 1)
        @page.destroy
        return_url = session[:came_from]
        session[:came_from] = nil
        if return_url && return_url != page_index_url(:root => @page)
          redirect_to return_url
        else
          redirect_to page_index_url(:page => @page.parent)
        end
      else
        session[:came_from] = request.env["HTTP_REFERER"]
      end
    else
      access_denied
    end
  end

  def clear_model_cache_with_site
    Page.current_site ||= @site || @page.root.site
    clear_model_cache_without_site
  end

  def new_with_site
    if user_authorized?
      new_without_site
    else
      access_denied
    end
  end

  def edit_with_site
    if user_authorized?
      edit_without_site
    else
      access_denied
    end 
  end

  protected

    def continue_url_with_site(options = {})
      options[:redirect_to] || (params[:continue] ? edit_admin_page_url(@page) : admin_pages_url)
    end

    def access_denied
      flash[:error] = 'Access denied.'
      redirect_to login_url
    end

    def user_developer?
      current_user and (current_user.developer? or current_user.admin?)
    end

    def user_authorized?
      user_developer? || (!current_user.nil? && current_user.owner?(@site))
    end

    def set_site
      id = params[:id] || params[:page_id] || params[:root] || params[:parent_id]
      @page = Page.find(id)
      @site = @page.root.site
    end

    def scope_layouts_to_site
      Layout.scoped_to_site(@site.id) do
        yield
      end
    end
end
