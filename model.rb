require 'bundler'
require 'dm-core'
require 'dm-migrations'
require 'feedjira'
require 'digest/sha1'
require 'net/http'
require 'uri'
require 'erb'

class Room
  include DataMapper::Resource
  property :id, Serial
  property :room_id, String, :length => 256, :required => true
  has n, :connections
  has n, :feeds, :through => :connections
end

class Feed
  include DataMapper::Resource
  property :id, Serial
  property :name, String, :length => 256, :required => true
  property :url, String, :length => 256, :required => true
  has n, :connections
  has n, :rooms, :through => :connections
  has n, :entries

  def self.crawl
    all.each do |feed|
      begin
        feedjira = Feedjira::Feed.fetch_and_parse feed.url
      rescue Exception => e
        puts "#{e.class.name}: #{e.message}"
        e.backtrace.each do |b|
          puts "\t from #{b}"
        end
      end
      if feedjira.nil? or (not feedjira.kind_of? Feedjira::FeedUtilities) or feedjira.entries.nil?
        next
      end
      feedjira.entries.sort{ |a, b| a.published <=> b.published }.each do |entry|
        begin
          if Entry.first({:feed_id => feed.id, :published => entry.published}).nil?
            entry = Entry.new(:title => entry.title, :url => entry.url, :published => entry.published, :feed => feed)
            feed.connections.each do |connection|
              room = connection.room
              text = "#{feed.name}: #{entry.title}\n#{entry.url}"
              request_url = "http://lingr.com/api/room/say?room=#{ERB::Util.url_encode(room.room_id)}&bot=#{ERB::Util.url_encode(ENV["BOT_ID"])}&text=#{ERB::Util.url_encode(text)}&bot_verifier=#{ERB::Util.url_encode(Digest::SHA1.hexdigest(ENV["BOT_ID"] + ENV["BOT_SECRET"]))}"
              uri = URI.parse(request_url)
              response = Net::HTTP.get_response(uri)
            end
            entry.save!
          end
        rescue Exception => e
          puts "#{e.class.name}: #{e.message}"
          e.backtrace.each do |b|
            puts "\t from #{b}"
          end
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
  property :url, String, :length => 256
  property :title, String, :length => 256
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

