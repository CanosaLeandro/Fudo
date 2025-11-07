require 'sidekiq'
require_relative 'sidekiq_client_middleware'

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqClientPayloadNormalizer
  end
end
