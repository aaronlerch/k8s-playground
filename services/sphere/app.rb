require 'sinatra'
require 'sinatra/quiet_logger'
require 'json'
require 'net/http'
require 'ddtrace'
require_relative 'sphere'
require_relative 'vault_secret_reader'

SERVICE_NAME = 'k8s-playground-sphere'

set :quiet_logger_prefixes, %w(livesz readyz)
register Sinatra::QuietLogger

set :seed_host, ENV['SEED_HOST'] || 'seed.seed.svc'
set :seed_port, ENV['SEED_PORT'] || '80'

secrets = VaultSecretReader.new("sphere").load
if secrets.loaded?
  envs = secrets.as_env
  puts "Loaded #{envs.keys.length} secrets from Vault"
  ENV.merge!(envs)
end

if ENV['SPHERE_LIGHTSTEP_TOKEN']
  # exclude readiness and liveness checks from tracing
  Datadog::Pipeline.before_flush do |trace|
    trace.delete_if { |span| span.get_tag('sinatra.route.path') =~ /livesz|readyz/i }
  end

  Datadog.configure do |c|
    trace_opts = { service_name: SERVICE_NAME, distributed_tracing: true }
    c.use :sinatra, trace_opts
    c.use :http, trace_opts

    c.distributed_tracing.propagation_inject_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
    c.distributed_tracing.propagation_extract_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]

    c.tracer tags: {
      'lightstep.service_name' => SERVICE_NAME,
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