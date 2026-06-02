module Api
  class CredentialsController < BaseController
    def index
      credentials = if params[:domain].present?
        escaped = Regexp.escape(params[:domain])
        @current_user.credentials.where(url: /(?:\/\/|\.)#{escaped}(?:\/|:|$)/)
      else
        @current_user.credentials
      end

      render json: credentials.map { |c| serialize_summary(c) }
    end

    def show
      credential = @current_user.credentials.find(params[:id])
      render json: serialize_full(credential)
    rescue Mongoid::Errors::DocumentNotFound
      render json: { error: "Credential not found" }, status: :not_found
    end

    def create
      credential = @current_user.credentials.build(credential_params)
      if credential.save
        render json: { id: credential.id.to_s, name: credential.name }, status: :created
      else
        render json: { errors: credential.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def credential_params
      params.permit(:name, :username, :password, :url, :note)
    end

    def serialize_summary(credential)
      { id: credential.id.to_s, name: credential.name, username: credential.username, url: credential.url }
    end

    def serialize_full(credential)
      { id: credential.id.to_s, name: credential.name, username: credential.username,
        url: credential.url, password: credential.password, note: credential.note }
    end
  end
end
