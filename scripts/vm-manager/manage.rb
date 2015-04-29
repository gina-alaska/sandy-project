#!/usr/bin/env ruby

require 'sinatra'
require 'haml'

get '/' do
  haml :index
end

get '/:host/:port' do
  @host = params[:host]
  @port = params[:port]
  haml :show
end
