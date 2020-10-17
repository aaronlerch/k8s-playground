require 'vault'

VAULT_ADDRESS = ENV['VAULT_ADDR'] || 'http://vault.vault.svc:8200'
SERVICE_ACCOUNT_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"

# set the default
Vault.address = VAULT_ADDRESS

# Monkey-patch the vault auth
# from: https://github.com/hashicorp/vault-ruby/pull/202
module Vault
    class Authenticate
        def kubernetes(role, service_account_path = nil, route = nil)
            route ||= '/v1/auth/kubernetes/login'
            service_account_path ||=
                '/var/run/secrets/kubernetes.io/serviceaccount/token'

            payload = {
                role: role,
                jwt: File.read(service_account_path)
            }

            json = client.post(
                route,
                JSON.fast_generate(payload)
            )

            secret = Secret.decode(json)
            client.token = secret.auth.client_token

            return secret
        end
    end
end

class VaultSecretReader

    class << self
        def configure(service_name = nil)
            secrets = VaultSecretReader.new(service_name).load
            if secrets.loaded?
                envs = secrets.as_env
                puts "Loaded #{envs.keys.length} secrets from Vault"
                ENV.merge!(envs)
            else
                puts "Skipped, or unable to load secrets from Vault"
            end
        end
    end

    attr_reader :secrets

    # supply a token to override the k8s auth
    def initialize(service_name = nil, role = nil, token = nil)
        @secrets = {}
        @loaded = false
        @client = nil
        @service_name = service_name || ENV['SERVICE_NAME']
        raise "A service name is required for reading vault secrets, either explicitly provided or via the SERVICE_NAME env var" if @service_name.nil?

        @role = role || service_name

        begin
            auth_token = token || Vault.auth.kubernetes(@role).auth.client_token
            @client = Vault::Client.new(address: VAULT_ADDRESS, token: auth_token)
        rescue Exception => e
            puts "ERROR: Error creating Vault Client -- #{e.message}"
        end
    end

    def loaded?
        @loaded
    end

    def load(kv_store = "secret")
        @secrets = {}

        begin
            if @client
                secret_names = @client.kv(kv_store).list(@service_name)
                secret_names.each do |name|
                    secret = @client.kv(kv_store).read("#{@service_name}/#{name}")
                    @secrets[name] = secret.data
                end
                @loaded = true
            end
        rescue Exception => e
            puts "ERROR: Error loading secrets from Vault -- #{e.message}"
        end

        return self
    end

    def as_env()
        results = {}
        @secrets.each do |scope_name, scope_value|
            unless scope_value.nil?
                scope_value.each do |secret_name, secret_value|
                    results["#{@service_name.to_s}_#{scope_name.to_s}_#{secret_name.to_s}"] = secret_value
                end
            end
        end
        return results.transform_keys { |k| k.upcase }
    end
end