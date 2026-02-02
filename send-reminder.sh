#!/bin/bash
#
# Japanese Holiday Reminder via WAHA (Bash Only Version)
# Sends WhatsApp reminders for Japanese holidays
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
HOLIDAYS_FILE="${SCRIPT_DIR}/holidays.json"
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

# Get current date info
CURRENT_HOUR=$(date +%H)
if [ -n "${TEST_DATE}" ]; then
    TODAY="${TEST_DATE}"
    TOMORROW=$(date -d "${TEST_DATE} +1 day" +%Y-%m-%d)
    log "TEST MODE: Using date ${TODAY}"
else
    TODAY=$(date +%Y-%m-%d)
    TOMORROW=$(date -d tomorrow +%Y-%m-%d)
fi

# Test mode - use TEST_HOUR if set
if [ -n "${TEST_HOUR}" ]; then
    # Validate TEST_HOUR
    case ${TEST_HOUR} in
        6|9|12|15|18)
            HOUR_INT=${TEST_HOUR}
            log "TEST MODE: Using hour ${HOUR_INT}"
            ;;
        *)
            log "ERROR: TEST_HOUR must be one of: 6, 9, 12, 15, 18"
            exit 1
            ;;
    esac
else
    # Valid reminder hours
    VALID_HOURS=("06" "09" "12" "15" "18")

    # Check if current hour is valid
    HOUR_VALID=0
    for H in "${VALID_HOURS[@]}"; do
        if [ "${CURRENT_HOUR}" = "${H}" ]; then
            HOUR_VALID=1
            break
        fi
    done

    if [ ${HOUR_VALID} -eq 0 ]; then
        log "INFO: Current hour ${CURRENT_HOUR} is not a valid reminder time"
        exit 0
    fi

    # Extract hour as integer for message selection
    HOUR_INT=$((10#${CURRENT_HOUR}))
fi

# Function to get holiday info from JSON
get_holiday() {
    local DATE=$1
    # Use jq if available, otherwise grep
    if command -v jq &> /dev/null; then
        jq -r ".[\"${DATE}\"] // empty" "${HOLIDAYS_FILE}"
    else
        # Fallback: grep the date from JSON
        grep -A 3 "\"${DATE}\"" "${HOLIDAYS_FILE}" 2>/dev/null
    fi
}

# Function to extract field from holiday JSON
get_field() {
    local JSON=$1
    local FIELD=$2
    if command -v jq &> /dev/null; then
        echo "${JSON}" | jq -r ".${FIELD}"
    else
        echo "${JSON}" | grep "\"${FIELD}\"" | sed 's/.*"'${FIELD}'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
    fi
}

# Check holidays
HOLIDAY_TOMORROW=$(get_holiday "${TOMORROW}")
HOLIDAY_TOMORROW_VALID=0
if [ -n "${HOLIDAY_TOMORROW}" ] && [ "${HOLIDAY_TOMORROW}" != "null" ]; then
    HOLIDAY_TOMORROW_VALID=1
fi

HOLIDAY_TODAY=$(get_holiday "${TODAY}")
HOLIDAY_TODAY_VALID=0
if [ -n "${HOLIDAY_TODAY}" ] && [ "${HOLIDAY_TODAY}" != "null" ]; then
    HOLIDAY_TODAY_VALID=1
fi

# Determine which holiday to use
if [ ${HOLIDAY_TOMORROW_VALID} -eq 1 ]; then
    DAY_TYPE="h-1"
    HOLIDAY_JSON="${HOLIDAY_TOMORROW}"
    NAME_ID=$(get_field "${HOLIDAY_JSON}" "name_id")
    NAME_JA=$(get_field "${HOLIDAY_JSON}" "name_ja")
    NAME_EN=$(get_field "${HOLIDAY_JSON}" "name_en")
    log "INFO: Tomorrow is ${NAME_ID}"
elif [ ${HOLIDAY_TODAY_VALID} -eq 1 ]; then
    DAY_TYPE="h"
    HOLIDAY_JSON="${HOLIDAY_TODAY}"
    NAME_ID=$(get_field "${HOLIDAY_JSON}" "name_id")
    NAME_JA=$(get_field "${HOLIDAY_JSON}" "name_ja")
    NAME_EN=$(get_field "${HOLIDAY_JSON}" "name_en")
    log "INFO: Today is ${NAME_ID}"
else
    log "INFO: No holiday today or tomorrow"
    exit 0
fi

# Generate message based on hour and day type (bilingual: ID + EN)
case ${HOUR_INT} in
    6)
        if [ "${DAY_TYPE}" = "h-1" ]; then
            MESSAGE="🌅 *PENGINGAT LIBUR JEPANG - JAPAN HOLIDAY REMINDER*

Besok libur nasional Jepang: **${NAME_ID}** (${NAME_JA}) 🇯🇵
Tomorrow is a Japanese national holiday: **${NAME_EN}** (${NAME_JA}) 🇯🇵

Jangan lupa persiapan ya! / Don't forget to prepare!"
        else
            MESSAGE="🌅 *SELAMAT LIBUR NASIONAL JEPANG - HAPPY JAPAN NATIONAL HOLIDAY!*

Hari ini: **${NAME_ID}** 🇯🇵 | Today: **${NAME_EN}** 🇯🇵
🎌 ${NAME_JA}

Happy holiday! 🎉"
        fi
        ;;
    9)
        if [ "${DAY_TYPE}" = "h-1" ]; then
            MESSAGE="☀️ *BESOK LIBUR JEPANG - TOMORROW IS JAPAN HOLIDAY!*

🎌 ${NAME_ID} | ${NAME_EN}
📛 ${NAME_JA}
📝 ${NAME_EN}

Semoga rencanamu lancar! / Have a great plan!"
        else
            MESSAGE="☀️ *HARI INI LIBUR JEPANG - TODAY IS JAPAN HOLIDAY!*

🎌 ${NAME_ID} | ${NAME_EN}
📛 ${NAME_JA}
📝 ${NAME_EN}

Selamat hari libur! / Happy holiday! 🇯🇵"
        fi
        ;;
    12)
        if [ "${DAY_TYPE}" = "h-1" ]; then
            MESSAGE="🌤️ *REMINDER H-1 LIBUR JEPANG*

Besok: **${NAME_ID}** | Tomorrow: **${NAME_EN}**
🇯🇵 ${NAME_JA}

Happy holiday weekend! 🎉"
        else
            MESSAGE="🌤️ *LIBUR NASIONAL JEPANG - JAPAN NATIONAL HOLIDAY*

Hari ini: **${NAME_ID}** (${NAME_JA})
Today: **${NAME_EN}** (${NAME_JA})

Tetap semangat walaupun libur! / Enjoy your day! 💪"
        fi
        ;;
    15)
        if [ "${DAY_TYPE}" = "h-1" ]; then
            MESSAGE="🌥️ *H-1 LIBUR JEPANG - JAPAN HOLIDAY TOMORROW*

Besok libur: **${NAME_ID}** (${NAME_EN})
Tomorrow is: **${NAME_EN}** (${NAME_ID})

Siapin rencana liburnya! / Get ready for the holiday! 🎌"
        else
            MESSAGE="🌥️ *SELAMAT HARI LIBUR - HAPPY HOLIDAY*

Merayakan **${NAME_ID}** 🇯🇵 | Celebrating **${NAME_EN}** 🇯🇵

${NAME_JA} - ${NAME_EN}

Enjoy your day! 🎌"
        fi
        ;;
    18)
        if [ "${DAY_TYPE}" = "h-1" ]; then
            MESSAGE="🌆 *PENGINGAT MALAM - EVENING REMINDER*

Besok libur Jepang: **${NAME_ID}** 🇯🇵
Tomorrow is Japan holiday: **${NAME_EN}** 🇯🇵

${NAME_JA} (${NAME_EN})

Selamat menikmati libur! / Enjoy the holiday! 🎉"
        else
            MESSAGE="🌆 *LIBUR JEPANG HARI INI - JAPAN HOLIDAY TODAY*

**${NAME_ID}** (${NAME_JA}) | **${NAME_EN}** (${NAME_JA})

Semoga harimu menyenangkan! / Have a wonderful day! 🎉🇯🇵"
        fi
        ;;
esac

log "Sending message..."

# Loop through each recipient
for CHAT_ID in ${WAHA_CHATS}; do
    log "Sending to ${CHAT_ID}..."

    # Mark chat as read first (anti-detection)
    MARK_READ_URL="${WAHA_URL}/api/default/chats/${CHAT_ID}/messages/read"
    MARK_READ_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${MARK_READ_URL}" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: ${WAHA_API_KEY}")

    MARK_READ_STATUS=$(echo "${MARK_READ_RESPONSE}" | tail -n1)
    log "Mark chat read: HTTP ${MARK_READ_STATUS}"

    # Small delay to appear more natural
    sleep 1

    # Build JSON payload using jq for proper escaping
    FINAL_JSON=$(jq -n \
        --arg chatId "${CHAT_ID}" \
        --arg text "${MESSAGE}" \
        --arg session "default" \
        '{chatId: $chatId, text: $text, session: $session}')

    # Send message
    SEND_TEXT_URL="${WAHA_URL}/api/sendText"
    SEND_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SEND_TEXT_URL}" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: ${WAHA_API_KEY}" \
        -d "${FINAL_JSON}")

    SEND_STATUS=$(echo "${SEND_RESPONSE}" | tail -n1)
    SEND_BODY=$(echo "${SEND_RESPONSE}" | head -n-1)

    log "Send message response: HTTP ${SEND_STATUS}"
    log "Response body: ${SEND_BODY}"

    if [ "${SEND_STATUS}" = "200" ] || [ "${SEND_STATUS}" = "201" ]; then
        log "✅ Message sent to ${CHAT_ID}"
    else
        log "❌ Failed to send to ${CHAT_ID}"
    fi

    # Delay between recipients
    sleep 2
done

log "Done!"
exit 0
