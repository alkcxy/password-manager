module Api
  class SessionsController < ActionController::API
    def create
      user = User.where(email: params[:email]).first
      unless user&.authenticate(params[:password])
        return render json: { error: "Invalid email or password" }, status: :unauthorized
      end

      api_token = ApiToken.generate_for(user)
      render json: { token: api_token.token, expires_at: api_token.expires_at.iso8601 },
             status: :created
    end

    def destroy
      api_token = ApiToken.where(token: params[:token]).first
      unless api_token
        return render json: { error: "Token not found" }, status: :not_found
      end

      api_token.destroy
      head :no_content
    end
  end
end
