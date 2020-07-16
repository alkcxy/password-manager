class ApplicationController < ActionController::Base
    before_action :authorized
    helper_method :current_user
    helper_method :logged_in?

    def current_user
        begin
            User.find(session[:user_id])
        rescue
            nil
        end
    end
    
    def logged_in?
        !current_user.nil? || !User.exists?
    end

    def authorized
        redirect_to '/welcome' unless logged_in?
     end
end
