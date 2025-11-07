#!/bin/bash
set -euo pipefail

echo "[start_sidekiq] Booting Sidekiq (RACK_ENV=${RACK_ENV:-production})"

# Optional: brief wait to allow docker healthchecks to settle
sleep 2


# Ensure database exists/migrated as well (idempotent, single attempt)
echo "[start_sidekiq] Preparing database (create/migrate)..."
if ! bundle exec rake db:create; then
	echo "[start_sidekiq] ERROR: db:create failed, aborting startup." >&2
	exit 1
fi

echo "[start_sidekiq] Starting Sidekiq"
exec bundle exec sidekiq -r ./api/api.rb