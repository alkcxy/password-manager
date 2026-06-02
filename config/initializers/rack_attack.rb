class Rack::Attack
  throttle("api/sessions", limit: 5, period: 60) do |req|
    req.ip if req.post? && req.path == "/api/sessions"
  end
end
