FROM ruby:3.2.2-slim

# Install system dependencies
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  git \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Add scripts directory to PATH
ENV PATH="/app/scripts:${PATH}"

# Set environment variables
ENV REDIS_URL=redis://redis:6379/0

# Make start scripts executable
RUN chmod +x scripts/*

# Default command (can be overridden in docker-compose.yml)
CMD ["./scripts/start_server.sh"]