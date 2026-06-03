source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.11'

gem 'rails', '~> 8.0'
gem 'puma', '~> 6.0'
gem 'bcrypt', '~> 3.1'
gem 'mongoid', '~> 9.0'
gem 'kaminari'
gem 'kaminari-mongoid'

gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'propshaft'

gem 'bootsnap', require: false
gem 'rack-attack'
gem 'rack-cors'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'debug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver', '~> 4.0'
end
