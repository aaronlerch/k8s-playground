require 'sinatra'
require 'sinatra/quiet_logger'
require 'json'
require 'net/http'
require 'ddtrace'
require_relative '../common/all'
require_relative 'sphere'

VERSION = ENV['VERSION_SHA']

set :quiet_logger_prefixes, %w(livesz readyz)
register Sinatra::QuietLogger

VaultSecretReader.configure
Lightstep.configure(lightstep_token: ENV['LIGHTSTEP_TOKEN'], version: VERSION)

set :seed_host, ENV['SEED_HOST'] || 'seed.seed.svc'
set :seed_port, ENV['SEED_PORT'] || '80'

get '/' do
  "Hello #{ENV['SERVICE_NAME']}! (#{VERSION})"
end

get '/sphere' do
    # build a sphere response
    uri = URI::HTTP.build(host: settings.seed_host, port: settings.seed_port, path: '/seed', query: 'start=5&stop=100')
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    radius = data['result'].to_i

    s = Sphere.new(radius)

    content_type :json
    s.to_h.to_json
end

get '/livesz' do
    halt 200
end

get '/readyz' do
    halt 200
end