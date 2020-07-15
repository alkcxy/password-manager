class SessionsController < ApplicationController
  skip_before_action :authorized

  def new
  end

  def create
    begin
      @user = User.find_by(email: params[:email])
      if @user && @user.authenticate(params[:password])
        session[:user_id] = @user.id
        redirect_to '/welcome'
      else
        redirect_to '/login'
      end
    rescue
      raise
      redirect_to '/login'
    end
  end

  def login
  end

  def welcome
  end
end
