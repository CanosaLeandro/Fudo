module Endpoints
  module Static
    extend self

    def authors(res)
      require_relative '../lib/api_error_handler'
      extend ApiErrorHandler
      begin
        authors_path = File.expand_path('../../AUTHORS', __FILE__)
        if File.exist?(authors_path)
          res.headers['cache-control'] = 'public, max-age=86400'
          res.headers['content-type'] = 'text/plain; charset=utf-8'
          res.write File.read(authors_path)
        else
          handle_not_found(res, 'AUTHORS file not found')
        end
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end

    def openapi(res)
      require_relative '../lib/api_error_handler'
      extend ApiErrorHandler
      begin
        openapi_path = File.expand_path('../../openapi.yaml', __FILE__)
        if File.exist?(openapi_path)
          res.headers['cache-control'] = 'no-store, no-cache, must-revalidate, max-age=0'
          res.headers['content-type'] = 'application/yaml; charset=utf-8'
          res.write File.read(openapi_path)
        else
          handle_not_found(res, 'openapi.yaml file not found')
        end
      rescue StandardError => e
        handle_api_error(res, e, status: 500, message: 'Internal server error')
      end
    end
  end
end
