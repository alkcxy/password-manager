#!/bin/bash

rm -f tmp/pids/server.pid
# gem update bundle
bundle install
# bundle update
# rails g mongoid:config
# rails webpacker:install
# yarn install
# yarn upgrade
# bin/rails g scaffold Credential name:string user:string password:PasswordType url:string note:text
# bin/rails g scaffold User name:string email:string password:string
rails g controller sessions new create login welcome 
# yarn add bootstrap jquery popper.js
rails s -p 3000 -b '0.0.0.0'
