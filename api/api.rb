require 'cuba'
require "cuba/safe"
require 'json'
require 'sequel'
require 'bcrypt'
require 'jwt'
require 'dotenv/load'
require 'rack/protection'
require 'yaml'

# Load environment variables
Dotenv.load

# Database connection
DB = Sequel.connect(YAML.load_file('config/database.yml')[ENV['RACK_ENV'] || 'development'])

Dir[File.join(__dir__, 'models', '*.rb')].sort.each do |file|
  require_relative "models/#{File.basename(file, '.rb')}"
end

Cuba.use Rack::Session::Cookie, secret: ENV['SESSION_SECRET']
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Cuba.plugin(Cuba::Safe)

Cuba.define do
  on post do
    on "api/v1" do
    end
  end
end