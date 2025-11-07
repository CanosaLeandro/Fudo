class Product < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:name, :cost]
    validates_max_length 255, :name
    validates_numeric :cost
    if cost && cost < 0
      errors.add(:cost, 'must be greater than or equal to 0')
    end
  end
end
