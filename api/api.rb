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

# Load paths
require_relative 'paths'

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
      on "login" do
        begin
          payload = JSON.parse(req.body.read)
          email = payload['email']
          password = payload['password']

          user = User.authenticate(email, password)
          
          if user
            token = JWT.encode(
              { user_id: user.id, exp: Time.now.to_i + 123456 },
              ENV['JWT_SECRET'],
              'HS256'
            )
            res.status = 200
            res.write({ token: token }.to_json)
          else
            res.status = 401
            res.write({ error: 'Invalid credentials' }.to_json)
          end
        rescue JSON::ParserError
          res.status = 400
          res.write({ error: 'Invalid JSON payload' }.to_json)
        rescue StandardError => e
          res.status = 500
          res.write({ error: 'Internal server error' }.to_json)
        end
      end
    end
  end
end