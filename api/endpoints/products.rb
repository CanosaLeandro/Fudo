require_relative '../lib/api_error_handler'
require_relative '../lib/auth_helper'

module Endpoints
  module Products
    def self.create(req, res, redis)
      extend ApiErrorHandler
      extend AuthHelper
      begin
        unless authorized_user!(req, res, redis)
          return
        end

        payload = JSON.parse(req.body.read)
        name = payload['name']
        cost = payload['cost']

        if name.nil? || name.to_s.strip.empty?
          handle_bad_request(res, 'name is required')
          return
        end

        if cost.nil?
          handle_bad_request(res, 'cost is required')
          return
        end

        CreateProductWorker.perform_async(payload)
        res.status = 202
        res.write({ message: "Product is being created..."}.to_json)
      rescue JSON::ParserError
        handle_bad_request(res, 'Invalid JSON payload')
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end

    def self.show(req, res, redis)
      extend ApiErrorHandler
      extend AuthHelper
      begin
        unless authorized_user!(req, res, redis)
          return
        end

        name = req.params['name']
        if name.nil? || name.strip.empty?
          handle_bad_request(res, 'Missing product name as param')
          return
        end

        p = Product.where(name: name).first
        if p
          res.status = 200
          res.write({ product: { id: p.id, name: p.name, cost: p.cost, image: p.image_url } }.to_json)
        else
          handle_not_found(res, 'Product not found')
        end
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end

    def self.list(req, res, redis)
      extend ApiErrorHandler
      extend AuthHelper
      begin
        unless authorized_user!(req, res, redis)
          return
        end
        products = Product.all.map do |p|
          {
            id: p.id,
            name: p.name,
            cost: p.cost,
            image: p.image_url
          }
        end
        res.status = 200
        res.write({ products: products }.to_json)
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end
  end
end
