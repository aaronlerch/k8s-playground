class Lightstep
    class << self
        def configure(lightstep_token, service_name = nil)
            unless lightstep_token
                puts "Skipping lightstep configuration, no token provided"
                return
            end

            service_name ||= "k8s-playground-#{ENV['SERVICE_NAME']}"

            # exclude standard readiness and liveness checks from tracing
            Datadog::Pipeline.before_flush do |trace|
                trace.delete_if { |span| span.get_tag('sinatra.route.path') =~ /livesz|readyz/i }
            end
            
            Datadog.configure do |c|
                trace_opts = { service_name: service_name, distributed_tracing: true }
                c.use :sinatra, trace_opts
                c.use :http, trace_opts
            
                c.distributed_tracing.propagation_inject_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
                c.distributed_tracing.propagation_extract_style = [Datadog::Ext::DistributedTracing::PROPAGATION_STYLE_B3]
            
                c.tracer tags: {
                  'lightstep.service_name' => service_name,
                  'lightstep.access_token' => lightstep_token
                }
            end
        end
    end    
end