require_relative 'spec_helper'
require 'json'

RSpec.describe 'POST /api/v1/login' do
  it 'returns a JWT token when credentials are valid' do

    fake_user = double('User', id: 42)
    allow(User).to receive(:authenticate).with('user', 'password').and_return(fake_user)

  header 'Content-Type', 'application/json'
  post '/api/v1/login', { user: 'user', password: 'password' }.to_json

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body).to include('token')
    expect(body['token']).to be_a(String)
  end

  it 'returns 401 when credentials are invalid' do
    allow(User).to receive(:authenticate).and_return(nil)

    header 'Content-Type', 'application/json'
    post '/api/v1/login', { user: 'nope@example.com', password: 'bad' }.to_json

    expect(last_response.status).to eq(401)
    body = JSON.parse(last_response.body)
    expect(body).to include('error')
  end
end

RSpec.describe 'POST /api/v1/logout' do
  let(:token) do
    JWT.encode({ user_id: 42, exp: Time.now.to_i + 3600 }, ENV['JWT_SECRET'] || 'testsecret', 'HS256')
  end

  it 'logs out with a valid token' do
    # Simular usuario autenticado
    header 'Authorization', "Bearer #{token}"
    post '/api/v1/logout'
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body).to include('message')
  end

  it 'returns 401 with invalid token' do
    header 'Authorization', 'Bearer invalidtoken'
    post '/api/v1/logout'
    expect(last_response.status).to eq(401)
    body = JSON.parse(last_response.body)
    expect(body).to include('error')
  end
end
