require 'bigdecimal'
require 'dotenv/load'
require 'erb'
require 'json'
require 'rack/protection'
require 'yaml'
require "cuba/safe"
require_relative 'endpoints/auth'
require_relative 'endpoints/products'
require_relative 'lib/api_error_handler'

# Database connection
begin
  # Prefer DATABASE_URL if provided (Docker, cloud envs)
  if ENV['DATABASE_URL'] && !ENV['DATABASE_URL'].empty?
    DB = Sequel.connect(ENV['DATABASE_URL'])
  else
    # Evaluate ERB in YAML (so production.url: <%= ENV['DATABASE_URL'] %> works)
    raw = File.read('config/database.yml')
    cfg = YAML.safe_load(ERB.new(raw).result, aliases: true)
    env = ENV['RACK_ENV'] || 'development'
    DB = Sequel.connect(cfg[env])
  end
rescue => e
  warn "[boot] Database connection failed: #{e.class} - #{e.message}"
  raise
end

# Redis connection for token blacklist
REDIS = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')

# Load paths and initialize application structure
require_relative 'paths'

Cuba.use Rack::Session::Cookie, secret: ENV['SESSION_SECRET']
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Cuba.plugin Cuba::Safe
Cuba.plugin Shield::Helpers

Cuba.define do
  on get do
    on "api/v1" do
      on "product" do
        Endpoints::Products.show(req, res, REDIS)
      end

      on "products" do
        Endpoints::Products.list(req, res, REDIS)
      end
    end

    on "AUTHORS" do
      Endpoints::Static.authors(res)
    end

    on "openapi.yaml" do
      Endpoints::Static.openapi(res)
    end
  end

  on post do
    on "api/v1" do
      # Auth endpoints
      on "login" do
        Endpoints::Auth.login(req, res)
      end
      
      on "logout" do
        Endpoints::Auth.logout(req, res, REDIS)
      end
      
      # Products endpoints
      on "product" do
        Endpoints::Products.create(req, res, REDIS)
      end
    end
  end
end