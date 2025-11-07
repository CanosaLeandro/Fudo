#!/bin/bash
set -euo pipefail

echo "[start_server] Booting API (RACK_ENV=${RACK_ENV:-production})"

# Optional: brief wait to allow docker healthchecks to settle
sleep 2


# Prepare database: create (idempotent) + migrate (single attempt)
echo "[start_server] Preparing database (create/migrate)..."
if ! bundle exec rake db:create; then
	echo "[start_server] ERROR: db:create failed, aborting startup." >&2
	exit 1
fi

# Start the Rack server
echo "[start_server] Starting Rack server on 0.0.0.0:9292"
exec bundle exec rackup -o 0.0.0.0 -p 9292