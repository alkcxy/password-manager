#!/bin/bash

rm -f tmp/pids/server.pid
# gem update bundle
# bundle install
# bundle update
# rails g mongoid:config
# rails webpacker:install
rake db:mongoid:create_indexes
yarn install --check-file
yarn upgrade
rails s -p 3000 -b '0.0.0.0'
