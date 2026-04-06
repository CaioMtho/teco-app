#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

EMAIL="teco.requester@gmail.com"
PASSWORD="senhaforte"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email)
      EMAIL="${2:-}"
      shift 2
      ;;
    --password)
      PASSWORD="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--email <email>] [--password <password>] [--dry-run]" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env file: $ENV_FILE" >&2
  exit 1
fi

# Export all variables from .env to current shell.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "Missing SUPABASE_URL in $ENV_FILE" >&2
  exit 1
fi

if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "Missing SUPABASE_ANON_KEY in $ENV_FILE" >&2
  exit 1
fi

SUPABASE_URL="${SUPABASE_URL%/}"

PAYLOAD=$(cat <<JSON
{
  "email": "$EMAIL",
  "password": "$PASSWORD",
  "data": {
    "full_name": "Test User",
    "type": "requester",
    "cpf_cnpj": "99999999999",
    "location": {
      "lat": -23.66281095728693,
      "lng": -46.72949808485587
    }
  }
}
JSON
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run enabled. Request payload:" >&2
  echo "$PAYLOAD"
  exit 0
fi

curl -sS -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
echo
