require 'bundler'
require './model'
require 'feedjira'
require 'digest/sha1'
require 'net/http'
require 'uri'

case ENV['RACK_ENV']
when 'production'
  DataMapper.setup(:default, ENV["DATABASE_URL"])
when 'test', 'development'
  DataMapper.setup(:default, "yaml:///tmp/feed2lingr")
else
  DataMapper.setup(:default, "yaml:///tmp/feed2lingr")
end

database_upgrade!


feeds = Feed.all
feeds.each do |feed|
  feedjira = Feedjira::Feed.fetch_and_parse feed.url
  title = feedjira.entries.first.title
  url = feedjira.entries.first.url
  published = feedjira.entries.first.published
  if Entry.first({:url => url, :published => published}).nil?
    entry = Entry.create(:title => title, :url => url, :published => published, :feed => feed)
    feed.connections.each do |connection, room = connection.room|
      text = "#{title}\n#{url}"
      request_url = "http://lingr.com/api/room/say?room=#{URI.encode(room.room_id)}&bot=#{URI.encode(ENV["BOT_ID"])}&text=#{URI.encode(text)}&bot_verifier=#{URI.encode(Digest::SHA1.hexdigest(ENV["BOT_ID"] + ENV["BOT_SECRET"]))}"
      uri = URI.parse(request_url)
      response = Net::HTTP.get_response(uri)
    end
  end
end

