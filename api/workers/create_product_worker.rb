require 'sidekiq'

class CreateProductWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(attrs)
    # attrs expected to be a Hash with string keys: 'name', 'description', 'cost', 'image_url'
    begin
      product = Product.new(
        name: attrs['name'],
        description: attrs['description'],
        cost: attrs['cost'] || 0,
        image_url: attrs['image_url']
      )

      if product.valid?
        # wait 5 seconds before saving the product
        sleep 5
        product.save
        logger.info "Product created(id=#{product.id})"
        true
      else
        logger.error "Product validation failed: #{product.errors.full_messages.join(', ')}"
        false
      end
    rescue => e
      logger.error "CreateProductWorker failed: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
end
