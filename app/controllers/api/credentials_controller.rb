module Api
  class CredentialsController < BaseController
    def index
      credentials = @current_user.credentials

      if params[:domain].present?
        escaped = Regexp.escape(params[:domain])
        credentials = credentials.where(url: /(?:\/\/|\.)#{escaped}(?:\/|:|$)/)
      end

      if params[:q].present?
        credentials = credentials.where("$text" => { "$search" => params[:q] })
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
    rescue Mongo::Error::OperationFailure => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end

    def update
      credential = @current_user.credentials.find(params[:id])
      if credential.update(credential_params)
        render json: { id: credential.id.to_s, name: credential.name }
      else
        render json: { errors: credential.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Mongoid::Errors::DocumentNotFound
      render json: { error: "Credential not found" }, status: :not_found
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
