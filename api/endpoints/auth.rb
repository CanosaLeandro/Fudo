require_relative '../lib/api_error_handler'
require_relative '../lib/auth_helper'
require 'jwt'

module Endpoints
  module Auth
    def self.login(req, res)
      extend ApiErrorHandler
      begin
        payload = JSON.parse(req.body.read)
        username = payload['user']
        password = payload['password']

        user_authenticated = User.authenticate(username, password)

        if user_authenticated
          begin
            login(User, username, password) if respond_to?(:login)
          rescue StandardError => e
            puts "login helper failed: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}" 
          end

          ttl = (ENV['JWT_TTL'] || 123456).to_i
          exp_time = Time.now.to_i + ttl

          token = JWT.encode(
            { user_id: user_authenticated.id, exp: exp_time },
            ENV['JWT_SECRET'],
            'HS256'
          )
          res.status = 200
          res.write({ token: token }.to_json)
        else
          handle_unauthorized(res, 'Invalid credentials')
        end
      rescue JSON::ParserError
        handle_bad_request(res, 'Invalid JSON payload')
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end

    def self.logout(req, res, redis)
      extend ApiErrorHandler
      begin
        auth_header = req.env['HTTP_AUTHORIZATION']
        if auth_header.nil? || !auth_header.start_with?('Bearer ')
          handle_unauthorized(res, 'Authorization header with Bearer token required')
          return
        end

        token = auth_header.split(' ')[1]
        begin
          decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })[0]
          exp = decoded['exp'] ? decoded['exp'].to_i : nil

          if exp && exp > Time.now.to_i
            ttl = exp - Time.now.to_i
            ttl = ttl.to_i
            redis.setex("blacklist:#{token}", ttl, '1')
            res.status = 200
            res.write({ message: 'Successfully logged out' }.to_json)
          else
            handle_unauthorized(res, 'Token already expired')
          end
        rescue JWT::DecodeError
          handle_unauthorized(res, 'Invalid token')
        end
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end
  end
end
