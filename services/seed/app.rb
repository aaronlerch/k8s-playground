require 'sinatra'
require 'sinatra/quiet_logger'
require 'json'
require 'ddtrace'
require_relative 'vault_secret_reader'

SERVICE_NAME = 'k8s-playground-seed'

set :quiet_logger_prefixes, %w(livesz readyz)
register Sinatra::QuietLogger

secrets = VaultSecretReader.new("seed").load
if secrets.loaded?
  envs = secrets.as_env
  puts "Loaded #{envs.keys.length} secrets from Vault"
  ENV.merge!(envs)
end

if ENV['SEED_LIGHTSTEP_TOKEN']
  # exclude readiness and liveness checks from tracing
  Datadog::Pipeline.before_flush do |trace|
    trace.delete_if { |span| span.name =~ /livesz|readyz/i }
  end

  Datadog.configure do |c|
    trace_opts = { service_name: SERVICE_NAME, distributed_tracing: true }
    c.use :sinatra, trace_opts
    c.use :http, trace_opts

    c.distributed_tracing.propagation_inject_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
    c.distributed_tracing.propagation_extract_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]

    c.tracer tags: {
      'lightstep.service_name' => SERVICE_NAME,
      'lightstep.access_token' => ENV['SEED_LIGHTSTEP_TOKEN']
    }
  end
end

get '/' do
  'Hello seed!'
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