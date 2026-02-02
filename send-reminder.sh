#!/bin/bash
#
# Japanese Holiday Reminder via WAHA
# Sends WhatsApp reminders for Japanese holidays
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/reminder-$(date +%Y%m%d).log"

# Create logs directory if not exists
mkdir -p "${LOG_DIR}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Check .env file
if [ ! -f "${ENV_FILE}" ]; then
    log "ERROR: .env file not found at ${ENV_FILE}"
    exit 1
fi

# Load environment variables
source "${ENV_FILE}"

# Validate required variables
if [ -z "${WAHA_URL}" ] || [ -z "${WAHA_API_KEY}" ] || [ -z "${WAHA_CHATS}" ]; then
    log "ERROR: Missing required environment variables"
    exit 1
fi

# Run Python checker to get message
MESSAGE_OUTPUT=$(python3 "${SCRIPT_DIR}/check-holiday.py" 2>&1)
PYTHON_EXIT=$?

if [ ${PYTHON_EXIT} -ne 0 ]; then
    log "INFO: ${MESSAGE_OUTPUT}"
    exit 0
fi

# Extract message from output
MESSAGE=$(echo "${MESSAGE_OUTPUT}" | grep "^MESSAGE:" | sed 's/^MESSAGE://')

if [ -z "${MESSAGE}" ]; then
    log "INFO: No message to send"
    exit 0
fi

log "Sending message: ${MESSAGE}"

# Mark chat as read first (anti-detection)
MARK_READ_URL="${WAHA_URL}/api/${WAHA_SESSION}/chats/${WAHA_CHATS}/messages/read"
MARK_READ_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${MARK_READ_URL}" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: ${WAHA_API_KEY}")

MARK_READ_STATUS=$(echo "${MARK_READ_RESPONSE}" | tail -n1)
log "Mark chat read: HTTP ${MARK_READ_STATUS}"

# Small delay to appear more natural
sleep 1

# Send message
SEND_TEXT_URL="${WAHA_URL}/api/sendText"
SEND_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SEND_TEXT_URL}" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: ${WAHA_API_KEY}" \
    -d "{
        \"chatId\": \"${WAHA_CHATS}\",
        \"text\": \"${MESSAGE}\",
        \"session\": \"${WAHA_SESSION}\"
    }")

SEND_STATUS=$(echo "${SEND_RESPONSE}" | tail -n1)
SEND_BODY=$(echo "${SEND_RESPONSE}" | head -n-1)

log "Send message response: HTTP ${SEND_STATUS}"
log "Response body: ${SEND_BODY}"

if [ "${SEND_STATUS}" = "200" ] || [ "${SEND_STATUS}" = "201" ]; then
    log "✅ Message sent successfully"
    exit 0
else
    log "❌ Failed to send message"
    exit 1
fi
