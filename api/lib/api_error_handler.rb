module ApiErrorHandler
  def handle_api_error(res, error, status: 500, message: nil)
    res.status = status
    res.headers['Content-Type'] = 'application/json; charset=utf-8'
    res.write({
      error: message || error.class.to_s,
      details: error.respond_to?(:message) ? error.message : error.to_s
    }.to_json)
  end

  def handle_not_found(res, message = 'Resource not found')
    res.status = 404
    res.headers['Content-Type'] = 'application/json; charset=utf-8'
    res.write({ error: message }.to_json)
  end

  def handle_bad_request(res, message = 'Bad request')
    res.status = 400
    res.headers['Content-Type'] = 'application/json; charset=utf-8'
    res.write({ error: message }.to_json)
  end

  def handle_unauthorized(res, message = 'Unauthorized')
    res.status = 401
    res.headers['Content-Type'] = 'application/json; charset=utf-8'
    res.write({ error: message }.to_json)
  end
end
