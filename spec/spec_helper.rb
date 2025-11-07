ENV['RACK_ENV'] = 'test'
ENV['JWT_SECRET'] = 'x' * 128

require 'shield'
require 'rspec'
require 'rack/test'
require 'yaml'
require 'sequel'
require File.expand_path('../../api/api', __FILE__)

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Cuba
  end
end

db_config = YAML.load_file(File.expand_path('../../config/database.yml', __FILE__))['test']
Sequel::Model.db = Sequel.connect(db_config)
