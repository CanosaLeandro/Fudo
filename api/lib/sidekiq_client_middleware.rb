require_relative 'payload_normalizer'

class SidekiqClientPayloadNormalizer
  def call(worker_class, job, queue, redis_pool)
    # Normalize the job args to native JSON-friendly types
    if job && job['args']
      job['args'] = PayloadNormalizer.normalize(job['args'])
    end
    yield
  end
end
