if (extension_id = ENV["EXTENSION_ID"].presence)
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins "chrome-extension://#{extension_id}"
      resource "/api/*", headers: :any, methods: [:get, :post, :delete, :options]
    end
  end
end
