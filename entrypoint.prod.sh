#!/bin/bash

rm -f tmp/pids/server.pid
rake db:mongoid:create_indexes
rails s -p 3000 -b '0.0.0.0'
