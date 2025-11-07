require 'json'

module AuthHelper
  def authorized_user!(req, res, redis)
    auth_header = req.env['HTTP_AUTHORIZATION']
    if auth_header.nil? || !auth_header.start_with?('Bearer ')
      res.status = 401
      res.write({ error: 'Authorization header with Bearer token required' }.to_json)
      return false
    end

    token = auth_header.split(' ')[1]
    # Verificar si el token está en la blacklist
    if redis.get("blacklist:#{token}")
      res.status = 401
      res.write({ error: 'Token is blacklisted' }.to_json)
      return false
    end

    begin
      decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })[0]
      user_id = decoded['user_id']
      user = User[user_id]
      unless user
        res.status = 401
        res.write({ error: 'User not found' }.to_json)
        return false
      end
    rescue JWT::DecodeError
      res.status = 401
      res.write({ error: 'Invalid token' }.to_json)
      return false
    end
    true
  end
end
