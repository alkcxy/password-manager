Rails.application.configure do
  config.enable_reloading = false
  config.action_view.cache_template_loading = true
  config.eager_load = ENV["CI"].present?

  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{1.hour.to_i}" }

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.action_dispatch.show_exceptions = :none

  config.action_controller.allow_forgery_protection = false

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test

  config.secret_key_base = "test_secret_key_base_not_for_production_use_only_local_test_env"
  ENV["SECRET_PM"] ||= "WkFKaXUzaGlRN3VoOFFEc1NTRmtHc25pRGRvbmZpMG8="
end
