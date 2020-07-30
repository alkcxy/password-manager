#!/bin/bash

rm -f tmp/pids/server.pid
# gem update bundle
# bundle install
# bundle update
# rails g mongoid:config
# rails webpacker:install
rake db:mongoid:create_indexes
yarn upgrade
yarn install --check-files
RAILS_ENV=production rails assets:precompile
rails s -p 3000 -b '0.0.0.0'
