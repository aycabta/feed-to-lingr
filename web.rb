require 'bundler'
require 'sinatra'
require 'slim'
require './model'

configure :production do
  DataMapper.setup(:default, ENV["DATABASE_URL"])
  database_upgrade!
end

configure :test, :development do
  DataMapper.setup(:default, "yaml:///tmp/feed2lingr")
  database_upgrade!
end

get '/end_of_the_point' do
  "\n"
end

get '/crawl' do
  Feed.crawl
  "\n"
end

get '/' do
  @connections = Connection.all
  slim :index
end

get '/add_room' do
  @rooms = Room.all
  slim :add_room
end

post '/add_room' do
  Room.create(:room_id => params[:room_id])
  redirect '/add_room', 302
end

get '/add_feed' do
  @feeds = Feed.all
  slim :add_feed
end

post '/add_feed' do
  Feed.create(:name => params[:name], :url => params[:url])
  redirect '/add_feed', 302
end

get '/add_associate' do
  @rooms = Room.all
  @feeds = Feed.all
  @connections = Connection.all
  slim :add_associate
end

post '/add_associate' do
  room = Room.get!(params[:room][:id])
  feed = Feed.get!(params[:feed][:id])
  Connection.create(:room => room, :feed => feed)
  redirect '/add_associate', 302
end
