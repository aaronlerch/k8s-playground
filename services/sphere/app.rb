require 'sinatra'
require 'json'
require 'net/http'
require 'ddtrace'
require_relative 'sphere'
require_relative 'vault_secret_reader'

set :seed_host, ENV['SEED_HOST'] || 'seed.seed.svc'
set :seed_port, ENV['SEED_PORT'] || '80'

secrets = VaultSecretReader.new("sphere").load
if secrets.loaded?
  envs = secrets.as_env
  puts "Vault secrets loaded! Loaded #{envs.keys.length} secrets"
  ENV.merge!(envs)
end

if ENV['SPHERE_LIGHTSTEP_TOKEN']
  puts "Configuring Lightstep using the retrieved SPHERE_LIGHTSTEP_TOKEN"
  Datadog.configure do |c|
    c.use :sinatra, { service_name: 'k8s-playground-sphere' }

    c.distributed_tracing.propagation_inject_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
    c.distributed_tracing.propagation_extract_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]

    c.tracer tags: {
      'lightstep.service_name' => 'k8s-playground-sphere',
      'lightstep.access_token' => ENV['SPHERE_LIGHTSTEP_TOKEN']
    }
  end
end

get '/' do
  'Hello sphere!'
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