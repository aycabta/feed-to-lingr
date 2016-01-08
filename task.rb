require 'bundler'
require './model'

DataMapper.setup(:default, ENV["DATABASE_URL"])
database_upgrade!

Feed.crawl

