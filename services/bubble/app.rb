require 'sinatra'
require 'sinatra/quiet_logger'
require 'json'
require 'net/http'
require 'ddtrace'
require_relative '../common/all'

set :quiet_logger_prefixes, %w(livesz readyz)
register Sinatra::QuietLogger

VaultSecretReader.configure
Lightstep.configure ENV['LIGHTSTEP_TOKEN']

set :seed_host, ENV['SEED_HOST'] || 'seed.seed.svc'
set :seed_port, ENV['SEED_PORT'] || '80'
set :sphere_host, ENV['SPHERE_HOST'] || 'sphere.sphere.svc'
set :sphere_port, ENV['SPHERE_PORT'] || '80'

get '/' do
  "Hello #{ENV['SERVICE_NAME']}!"
end

get '/bubbles' do
    # get a bunch of spheres which are collectively bubbles, and give each one a coordinate
    
    # how many bubbles to create?
    uri = URI::HTTP.build(host: settings.seed_host, port: settings.seed_port, path: '/seed', query: 'start=5&stop=20')
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    count = data['result'].to_i

    bubbles = []

    uri = URI::HTTP.build(host: settings.sphere_host, port: settings.sphere_port, path: '/sphere')
    count.times do
        response = Net::HTTP.get(uri)
        sphere_data = JSON.parse(response)
        bubbles << sphere_data
    end

    content_type :json
    bubbles.to_json
end

get '/livesz' do
    halt 200
end

get '/readyz' do
    halt 200
end