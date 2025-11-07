require 'shield'

class User < Sequel::Model
  include Shield::Model

  plugin :validation_helpers

  def validate
    super
    validates_presence [:user]
    validates_unique :user
  end

  def self.authenticate(username, password)
    user = self.find(user: username)
    return nil unless user

    # Use Shield::Password to verify the stored password hash
    if Shield::Password.check(password, user.crypted_password)
      user
    else
      nil
    end
  end
end