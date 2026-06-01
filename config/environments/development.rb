Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = { 'cache-control' => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  config.secret_key_base = "dev_secret_key_base_not_for_production_use_only_local_development_env" # pragma: allowlist secret
  ENV["SECRET_PM"] ||= "WkFKaXUzaGlRN3VoOFFEc1NTRmtHc25pRGRvbmZpMG8=" # pragma: allowlist secret
end
