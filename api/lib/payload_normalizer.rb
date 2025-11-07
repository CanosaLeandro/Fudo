require 'bigdecimal'
require 'date'

module PayloadNormalizer
  module_function

  def normalize(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(k, v), h|
        h[k.to_s] = normalize(v)
      end
    when Array
      obj.map { |v| normalize(v) }
    when BigDecimal
      # Redondear a 2 decimales y convertir a string
      obj.round(2).to_s('F')
    when Date, DateTime, Time
      obj.iso8601
    when Symbol
      obj.to_s
    else
      if obj.is_a?(String) || obj.is_a?(Integer) || obj.is_a?(Float) || obj == true || obj == false || obj.nil?
        obj
      else
        obj.to_s
      end
    end
  end
end
