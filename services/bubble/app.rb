require 'sinatra'
require 'sinatra/quiet_logger'
require 'json'
require 'net/http'
require 'ddtrace'
require_relative '../common/all'
#require_relative 'sphere'

set :quiet_logger_prefixes, %w(livesz readyz)
register Sinatra::QuietLogger

VaultSecretReader.configure
Lightstep.configure ENV["#{ENV['SERVICE_NAME']}_LIGHTSTEP_TOKEN"]

set :sphere_host, ENV['SPHERE_HOST'] || 'sphere.sphere.svc'
set :sphere_port, ENV['SPHERE_PORT'] || '80'

get '/' do
  "Hello #{ENV['SERVICE_NAME']}!"
end

get '/bubbles' do
    # get a bunch of spheres which are collectively bubbles, and give each one a coordinate
    "coming soon!"

    # build a sphere response
    # uri = URI::HTTP.build(host: settings.seed_host, port: settings.seed_port, path: '/seed', query: 'start=5&stop=100')
    # response = Net::HTTP.get(uri)
    # data = JSON.parse(response)
    # radius = data['result'].to_i

    # s = Sphere.new(radius)

    # content_type :json
    # s.to_h.to_json
end

get '/livesz' do
    halt 200
end

get '/readyz' do
    halt 200
end