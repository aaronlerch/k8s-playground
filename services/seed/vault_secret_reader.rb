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
    attr_reader :client, :service_name, :role
    attr_reader :secrets

    # supply a token to override the k8s auth
    def initialize(service_name, role = nil, token = nil)
        @secrets = {}
        @loaded = false
        @client = nil
        @service_name = service_name
        @role = role || service_name

        begin
            auth_token = token || Vault.auth.kubernetes(role)
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
                puts "Loaded #{secret_names.length} secrets from Vault"
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
                    results["#{service_name.to_s}_#{scope_name.to_s}_#{secret_name.to_s}"] = secret_value
                end
            end
        end
        return results.transform_keys { |k| k.upcase }
    end
end