#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-backups}"
BACKUP_FILE="${1:-$(ls -1t "${BACKUP_DIR}"/bookings_*.dump 2>/dev/null | head -n 1 || true)}"

if [[ -z "${BACKUP_FILE}" || ! -f "${BACKUP_FILE}" ]]; then
  echo "No backup found. Usage: $0 [backups/bookings_YYYYMMDD_HHMMSS.dump]"
  exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESTORE_DB="bookings_restore_${TIMESTAMP}"

echo "Creating fresh restore database: ${RESTORE_DB}"

docker compose exec -T postgres \
  psql -U appuser -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "CREATE DATABASE ${RESTORE_DB};"

cat "${BACKUP_FILE}" | docker compose exec -T postgres \
  pg_restore \
  -U appuser \
  -d "${RESTORE_DB}" \
  --no-owner \
  --no-privileges \
  --exit-on-error

BOOKINGS_COUNT="$(
  docker compose exec -T postgres \
    psql -U appuser -d "${RESTORE_DB}" -tAc \
    "SELECT COUNT(*) FROM hotel_bookings;"
)"

EVENTS_COUNT="$(
  docker compose exec -T postgres \
    psql -U appuser -d "${RESTORE_DB}" -tAc \
    "SELECT COUNT(*) FROM booking_events;"
)"

echo "Restore completed successfully."
echo "Database: ${RESTORE_DB}"
echo "hotel_bookings: ${BOOKINGS_COUNT}"
echo "booking_events: ${EVENTS_COUNT}"
