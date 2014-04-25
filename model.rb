require 'bundler'
require 'dm-core'
require 'dm-migrations'

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

