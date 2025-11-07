require './api/api'

require 'bundler/setup'

require 'dotenv'
Dotenv.load

# Enable gzip compression when client accepts it
use Rack::Deflater

run Cuba