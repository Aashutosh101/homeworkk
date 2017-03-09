class ApplicationController < ActionController::Base
	PREFERED_HOST = 'www.christopherbot.co'
	before_filter :redirect_to_prefered_host


  protected

  def set_user_api_token
    RequestStore.store[:my_api_token] = current_user.api_token # or something similar based on `session`
  end

	#this is the method to redirect someone to christopherbot.co if they are on christopherbot.herokuapp.com
  def redirect_to_prefered_host
  	if Rails.env.production? && request.host != PREFERED_HOST
    	redirect_to(host: PREFERED_HOST)
  	end
	end

end
