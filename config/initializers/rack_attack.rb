Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

class Rack::Attack
  throttle("api/sessions", limit: 5, period: 60) do |req|
    req.ip if req.post? && req.path == "/api/sessions"
  end

  self.throttled_responder = lambda do |_env|
    [429, { "Content-Type" => "application/json" },
     [{ error: "Too many requests. Retry in a minute." }.to_json]]
  end
end
