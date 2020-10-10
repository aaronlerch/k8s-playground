require 'sinatra'
require 'json'
require 'ddtrace'
require_relative 'vault_secret_reader'

secrets = VaultSecretReader.new("seed").load
if secrets.loaded?
  ENV.merge!(secrets.as_env)
end

if ENV['SEED_LIGHTSTEP_TOKEN']
  Datadog.configure do |c|
    c.use :sinatra, { service_name: 'k8s-playground-seed' }

    c.distributed_tracing.propagation_inject_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
    c.distributed_tracing.propagation_extract_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]

    c.tracer tags: {
      'lightstep.service_name' => 'k8s-playground-seed',
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