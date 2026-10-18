
#!/usr/bin/env bash

set -Eeuo pipefail

# Find the project root, regardless of the current directory.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

BASE_URL="http://localhost:8080"

usage() {
    cat <<'HELP'
Usage: ./scripts/ops.sh <command>

Commands:
  up       Build and start API and PostgreSQL
  down     Stop containers without deleting database data
  status   Show service status and health
  logs     Follow the latest API logs
  smoke    Test health, user creation, and notification creation
  help     Show available commands

Examples:
  ./scripts/ops.sh up
  ./scripts/ops.sh status
  ./scripts/ops.sh logs
  ./scripts/ops.sh smoke
  ./scripts/ops.sh down
HELP
}

error() {
    echo "ERROR: $*" >&2
    exit 1
}

# Verify required tools are available.
command -v docker >/dev/null 2>&1 ||
    error "Docker is not installed or is not available in PATH."

docker compose version >/dev/null 2>&1 ||
    error "Docker Compose is unavailable. Start Docker Desktop and try again."

case "${1:-help}" in
    up)
        echo "Starting API and PostgreSQL..."
        docker compose up -d --build
        docker compose ps
        ;;

    down)
        echo "Stopping the stack..."
        echo "Database volume will be preserved."
        docker compose down
        ;;

    status|ps)
        echo "Checking service status..."
        docker compose ps
        echo
        echo "Checking API health..."

        if curl --fail --silent --show-error "$BASE_URL/health"; then
            echo
            echo "API health check passed."
        else
            error "API is not healthy. Run './scripts/ops.sh logs' to investigate."
        fi
        ;;

    logs)
        echo "Following API logs. Press Ctrl+C to stop."
        docker compose logs -f --tail=100 api
        ;;

    smoke)
        echo "1. Checking API health..."
        HEALTH_RESPONSE=$(curl --fail --silent --show-error \
            "$BASE_URL/health") ||
            error "Health request failed. Start the stack with './scripts/ops.sh up'."

        echo "$HEALTH_RESPONSE" |
            grep -q '"status"[[:space:]]*:[[:space:]]*"ok"' ||
            error "Health endpoint returned an unexpected response: $HEALTH_RESPONSE"

        echo "Health check passed."

        echo "2. Creating a test user..."
        USER_RESPONSE=$(curl --fail --silent --show-error \
            -X POST "$BASE_URL/users" \
            -H "Content-Type: application/json" \
            -d '{"name":"Ops Smoke Test User"}') ||
            error "Could not create a test user."

        USER_ID=$(printf '%s' "$USER_RESPONSE" |
            grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' |
            head -n 1 |
            grep -o '[0-9]*$') ||
            error "Could not read the user ID from the API response."

        [[ -n "$USER_ID" ]] ||
            error "API did not return a valid user ID: $USER_RESPONSE"

        echo "User created successfully (ID: $USER_ID)."

        echo "3. Creating a test notification..."
        NOTIFICATION_RESPONSE=$(curl --fail --silent --show-error \
            -X POST "$BASE_URL/notifications" \
            -H "Content-Type: application/json" \
            -d "{\"user_id\":$USER_ID,\"title\":\"Ops Smoke Test\",\"body\":\"Test notification from ops.sh\"}") ||
            error "Could not create a notification for user $USER_ID."

        echo "Notification response: $NOTIFICATION_RESPONSE"

        printf '%s' "$NOTIFICATION_RESPONSE" |
            grep -q '"title"[[:space:]]*:[[:space:]]*"Ops Smoke Test"' ||
            error "Notification response did not contain the expected title."

        echo "Notification created successfully."
        echo "All smoke tests passed."
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        echo "ERROR: Unknown or missing command: ${1:-}"
        usage
        exit 1
        ;;
esac
