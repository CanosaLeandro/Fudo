require 'bcrypt'

class User < Sequel::Model
  plugin :validation_helpers

  # Virtual attribute for plain password
  def password=(new_password)
    @password = new_password
    if new_password && !new_password.to_s.empty?
      self.password_digest = BCrypt::Password.create(new_password)
    end
  end

  def password
    @password
  end

  # Return self when password matches, otherwise false
  def authenticate(password)
    return false unless password_digest
    begin
      BCrypt::Password.new(password_digest) == password ? self : false
    rescue BCrypt::Errors::InvalidHash
      false
    end
  end

  def validate
    super
    validates_presence [:email, :password_digest]
    validates_unique :email
    validates_format /\A[^@\s]+@[^@\s]+\z/, :email
  end

  def self.authenticate(email, password)
    user = self.find(email: email)
    user && user.authenticate(password) ? user : nil
  end
end