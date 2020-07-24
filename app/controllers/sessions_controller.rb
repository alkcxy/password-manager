class SessionsController < ApplicationController
  skip_before_action :authorized

  def new
  end

  def create
    begin
      @user = User.find_by(email: params[:email])
      if @user && @user.authenticate(params[:password])
        session[:user_id] = @user.id
      else
        flash = "Login non valida"
      end
    rescue
      flash = "Login non valida"
    end
    redirect_to root_url, notice: flash
  end

  def login
  end

  def welcome
  end

  def logout
    cookies.delete(:user_id)
    session.delete(:user_id)
    reset_session
    redirect_to root_url, notice: "Sei stato disconnesso"
  end
end
