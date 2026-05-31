class CredentialsController < ApplicationController
  before_action :set_credential, only: [:show, :edit, :update, :destroy, :reveal_password, :hide_password, :copy_password]
  rescue_from Mongoid::Errors::DocumentNotFound do
    head :not_found
  end
  rescue_from ActionController::UnknownFormat do
    head :not_acceptable
  end

  def index
    @credentials = Credential.only(:name, :username, :url, :note).where(user_id: current_user.id).order_by([:name, :asc]).page(params[:page])
    @credentials = @credentials.where('$text' => {'$search' => params[:q]}) if params[:q].present?
  end

  def show
  end

  def new
    @credential = Credential.new
  end

  def edit
  end

  def create
    @credential = Credential.new(credential_params)
    @credential.user = current_user

    if @credential.save
      redirect_to @credential, notice: 'Credential was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    attrs = credential_params
    attrs = attrs.except(:password) if attrs[:password].blank?
    if @credential.update(attrs)
      redirect_to @credential, notice: 'Credential was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reveal_password
  end

  def hide_password
  end

  def copy_password
    respond_to do |format|
      format.json { render json: { password: @credential.password.to_s } }
    end
  end

  def destroy
    @credential.destroy
    redirect_to credentials_url, notice: 'Credential was successfully destroyed.'
  end

  private

  def set_credential
    @credential = current_user.credentials.find(params[:id])
  end

  def credential_params
    params.require(:credential).permit(:name, :username, :password, :url, :note)
  end
end
