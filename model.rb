require 'bundler'
require 'dm-core'
require 'dm-migrations'
require 'feedjira'
require 'digest/sha1'
require 'net/http'
require 'uri'

class Room
  include DataMapper::Resource
  property :id, Serial
  property :room_id, String, :length => 256, :required => true
  #has n, :feeds, :through => Resource
  has n, :connections
  has n, :feeds, :through => :connections
end

class Feed
  include DataMapper::Resource
  property :id, Serial
  property :name, String, :length => 256, :required => true
  property :url, String, :length => 256, :required => true
  #has n, :rooms, :through => Resource
  has n, :connections
  has n, :rooms, :through => :connections
  has n, :entries

  def self.crawl
    all.each do |feed|
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
  end
end

class Connection
  include DataMapper::Resource
  belongs_to :room, :key => true
  belongs_to :feed, :key => true
end

class Entry
  include DataMapper::Resource
  property :id, Serial
  property :url, String, :length => 256, :required => true
  property :title, String, :length => 256, :required => true
  property :published, String, :length => 256, :required => true
  belongs_to :feed
end

DataMapper.finalize

def database_upgrade!
  Room.auto_upgrade!
  Feed.auto_upgrade!
  Connection.auto_upgrade!
  Entry.auto_upgrade!
end

