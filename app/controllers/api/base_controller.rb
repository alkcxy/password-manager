module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      raw_token = extract_bearer_token
      unless raw_token
        return render json: { error: "Authorization header missing or malformed" },
                      status: :unauthorized
      end

      @api_token = ApiToken.where(token: raw_token).first
      unless @api_token && !@api_token.expired?
        return render json: { error: "Invalid or expired token" },
                      status: :unauthorized
      end

      @current_user = @api_token.user
    end

    def extract_bearer_token
      header = request.headers["Authorization"]
      return nil unless header&.start_with?("Bearer ")
      header.delete_prefix("Bearer ").strip.presence
    end
  end
end
