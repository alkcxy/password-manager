Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "chrome-extension://#{ENV.fetch('EXTENSION_ID')}"

    resource "/api/*",
             headers: :any,
             methods: [:get, :post, :delete, :options]
  end
end
