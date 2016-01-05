require 'bundler'
require './model'

configure :production do
  DataMapper.setup(:default, ENV["DATABASE_URL"])
  database_upgrade!
end

configure :test, :development do
  DataMapper.setup(:default, "yaml:///tmp/feed2lingr")
  database_upgrade!
end

Feed.crawl

