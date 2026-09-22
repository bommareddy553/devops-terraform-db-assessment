

#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/bookings_${TIMESTAMP}.dump"

mkdir -p "${BACKUP_DIR}"

echo "Creating PostgreSQL backup: ${BACKUP_FILE}"

docker compose exec -T postgres \
  pg_dump \
  -U appuser \
  -d bookings \
  -Fc \
  > "${BACKUP_FILE}"

test -s "${BACKUP_FILE}"

echo "Backup completed successfully."
echo "File: ${BACKUP_FILE}"
