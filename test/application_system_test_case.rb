require "test_helper"
require "socket"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SELENIUM_REMOTE_URL"]
    HOST_IP = Socket.ip_address_list.select(&:ipv4?).reject(&:ipv4_loopback?).first.ip_address

    Capybara.server_host = HOST_IP
    Capybara.server_port = 3001
    Capybara.app_host   = "http://#{HOST_IP}:3001"

    driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: {
      browser: :remote,
      url: ENV["SELENIUM_REMOTE_URL"]
    }
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
end
