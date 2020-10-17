require 'sinatra'
require 'sinatra/quiet_logger'
require 'json'
require 'ddtrace'
require_relative '../common/all'

set :quiet_logger_prefixes, %w(livesz readyz)
register Sinatra::QuietLogger

VaultSecretReader.configure
Lightstep.configure ENV['LIGHTSTEP_TOKEN']

get '/' do
  "Hello #{ENV['SERVICE_NAME']}!"
end

get '/seed' do
    start = params['start'] || 0
    stop = params['stop'] || 1
    r = Range.new(start.to_i, stop.to_i)

    content_type :json
    { result: rand(r) }.to_json
end

get '/livesz' do
    halt 200
end

get '/readyz' do
    halt 200
end