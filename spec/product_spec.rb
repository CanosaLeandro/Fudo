require_relative '../api/api'
require_relative '../api/models/product'
require_relative '../api/models/user'
require 'rack/test'
require 'json'

describe 'Product API endpoints' do
  include Rack::Test::Methods

  def app
    Cuba
  end

  let(:jwt_secret) { ENV['JWT_SECRET'] || 'testsecret' }
  let(:user) { double('User', id: 1) }
  let(:token) do
    JWT.encode({ user_id: user.id, exp: Time.now.to_i + 3600 }, jwt_secret, 'HS256')
  end

  before do
    Product.where(name: 'TestProduct').delete
  end

  it 'creates a product with valid token' do
    header 'Authorization', "Bearer #{token}"
    post '/api/v1/product', { name: 'TestProduct', cost: 100 }.to_json, { 'CONTENT_TYPE' => 'application/json' }
    expect(last_response.status).to eq 202
    expect(JSON.parse(last_response.body)['job']).not_to be_nil
  end

  it 'rejects product creation with invalid token' do
    header 'Authorization', 'Bearer invalidtoken'
    post '/api/v1/product', { name: 'TestProduct', cost: 100 }.to_json, { 'CONTENT_TYPE' => 'application/json' }
    expect(last_response.status).to eq 401
  end

  it 'lists products with valid token' do
    Product.create(name: 'TestProduct', cost: 100)
    header 'Authorization', "Bearer #{token}"
    get '/api/v1/products'
    expect(last_response.status).to eq 200
    products = JSON.parse(last_response.body)['products']
    expect(products.any? { |p| p['name'] == 'TestProduct' }).to be true
  end

  it 'searches product by name' do
    Product.create(name: 'TestProduct', cost: 100)
    header 'Authorization', "Bearer #{token}"
    get '/api/v1/product?name=TestProduct'
    expect(last_response.status).to eq 200
    product = JSON.parse(last_response.body)['product']
    expect(product['name']).to eq 'TestProduct'
  end

  it 'returns 404 for missing product' do
    header 'Authorization', "Bearer #{token}"
    get '/api/v1/product?name=NoSuchProduct'
    expect(last_response.status).to eq 404
  end
end
