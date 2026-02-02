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
CURRENT_DOW=$(date +%u)  # 1=Monday, 7=Sunday

if [ -n "${TEST_DATE}" ]; then
    TODAY="${TEST_DATE}"
    TOMORROW=$(date -d "${TEST_DATE} +1 day" +%Y-%m-%d)
    # For test mode, allow overriding DOW
    CURRENT_DOW=${TEST_DOW:-$(date -d "${TEST_DATE}" +%u)}
    log "TEST MODE: Using date ${TODAY} (DOW: ${CURRENT_DOW})"
else
    TODAY=$(date +%Y-%m-%d)
    TOMORROW=$(date -d tomorrow +%Y-%m-%d)
fi

# Determine which dates to check based on day of week
CHECK_DATES=()
DAYS_UNTIL=()

case ${CURRENT_DOW} in
    1|2|3|4)  # Monday-Thursday: check tomorrow
        CHECK_DATES=("${TOMORROW}")
        DAYS_UNTIL=(1)
        ;;
    5)  # Friday: check Saturday, Sunday, Monday
        SAT=$(date -d "${TODAY} +1 day" +%Y-%m-%d)
        SUN=$(date -d "${TODAY} +2 days" +%Y-%m-%d)
        MON=$(date -d "${TODAY} +3 days" +%Y-%m-%d)
        CHECK_DATES=("${SAT}" "${SUN}" "${MON}")
        DAYS_UNTIL=(1 2 3)
        ;;
    6|7)  # Saturday-Sunday: only check Monday
        MON=$(date -d "${TODAY} +1 day" +%Y-%m-%d)
        if [ ${CURRENT_DOW} -eq 6 ]; then
            # Saturday, Monday is +2 days
            MON=$(date -d "${TODAY} +2 days" +%Y-%m-%d)
        fi
        CHECK_DATES=("${MON}")
        DAYS_UNTIL=($(date -d "${MON}" +%s))
        DAYS_UNTIL=(($(($(date -d "${MON}" +%s) - $(date -d "${TODAY}" +%s))) / 86400))
        ;;
esac

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

# Check holidays in the determined dates
FOUND_HOLIDAY=0
TARGET_DATE=""
DAYS_UNTIL_HOLIDAY=0

# First check if today is a holiday (special case)
HOLIDAY_TODAY=$(get_holiday "${TODAY}")
if [ -n "${HOLIDAY_TODAY}" ] && [ "${HOLIDAY_TODAY}" != "null" ]; then
    FOUND_HOLIDAY=1
    TARGET_DATE="${TODAY}"
    DAYS_UNTIL_HOLIDAY=0
    HOLIDAY_JSON="${HOLIDAY_TODAY}"
    NAME_ID=$(get_field "${HOLIDAY_JSON}" "name_id")
    NAME_JA=$(get_field "${HOLIDAY_JSON}" "name_ja")
    NAME_EN=$(get_field "${HOLIDAY_JSON}" "name_en")
    log "INFO: Today is ${NAME_ID}"
fi

# If today is not a holiday, check upcoming dates
if [ ${FOUND_HOLIDAY} -eq 0 ]; then
    for i in "${!CHECK_DATES[@]}"; do
        CHECK_DATE="${CHECK_DATES[$i]}"
        HOLIDAY=$(get_holiday "${CHECK_DATE}")
        if [ -n "${HOLIDAY}" ] && [ "${HOLIDAY}" != "null" ]; then
            FOUND_HOLIDAY=1
            TARGET_DATE="${CHECK_DATE}"
            DAYS_UNTIL_HOLIDAY=${DAYS_UNTIL[$i]}
            HOLIDAY_JSON="${HOLIDAY}"
            NAME_ID=$(get_field "${HOLIDAY_JSON}" "name_id")
            NAME_JA=$(get_field "${HOLIDAY_JSON}" "name_ja")
            NAME_EN=$(get_field "${HOLIDAY_JSON}" "name_en")
            log "INFO: Found holiday in ${DAYS_UNTIL_HOLIDAY} days: ${NAME_ID}"
            break
        fi
    done
fi

if [ ${FOUND_HOLIDAY} -eq 0 ]; then
    log "INFO: No upcoming holiday found"
    exit 0
fi

# Set DAY_TYPE based on days until holiday
if [ ${DAYS_UNTIL_HOLIDAY} -eq 0 ]; then
    DAY_TYPE="h"
else
    DAY_TYPE="h-${DAYS_UNTIL_HOLIDAY}"
fi

# Generate message based on hour and day type (bilingual: ID + EN)
case ${HOUR_INT} in
    6)
        if [ "${DAY_TYPE}" = "h" ]; then
            MESSAGE="🌅 *SELAMAT LIBUR NASIONAL JEPANG - HAPPY JAPAN NATIONAL HOLIDAY!*

Hari ini: **${NAME_ID}** 🇯🇵 | Today: **${NAME_EN}** 🇯🇵
🎌 ${NAME_JA}

Happy holiday! 🎉"
        else
            # H-1, H-2, H-3
            if [ ${DAYS_UNTIL_HOLIDAY} -eq 1 ]; then
                DAYS_TEXT="Besok | Tomorrow"
            elif [ ${DAYS_UNTIL_HOLIDAY} -eq 2 ]; then
                DAYS_TEXT="Lusa | In 2 days"
            else
                DAYS_TEXT="Dalam ${DAYS_UNTIL_HOLIDAY} hari | In ${DAYS_UNTIL_HOLIDAY} days"
            fi
            MESSAGE="🌅 *PENGINGAT LIBUR JEPANG - JAPAN HOLIDAY REMINDER*

${DAYS_TEXT} libur nasional Jepang: **${NAME_ID}** (${NAME_JA}) 🇯🇵
${DAYS_TEXT} is a Japanese national holiday: **${NAME_EN}** (${NAME_JA}) 🇯🇵

Jangan lupa persiapan ya! / Don't forget to prepare!"
        fi
        ;;
    9)
        if [ "${DAY_TYPE}" = "h" ]; then
            MESSAGE="☀️ *HARI INI LIBUR JEPANG - TODAY IS JAPAN HOLIDAY!*

🎌 ${NAME_ID} | ${NAME_EN}
📛 ${NAME_JA}
📝 ${NAME_EN}

Selamat hari libur! / Happy holiday! 🇯🇵"
        else
            # H-1, H-2, H-3
            if [ ${DAYS_UNTIL_HOLIDAY} -eq 1 ]; then
                DAYS_TEXT="Besok | Tomorrow"
            elif [ ${DAYS_UNTIL_HOLIDAY} -eq 2 ]; then
                DAYS_TEXT="Lusa | In 2 days"
            else
                DAYS_TEXT="${DAYS_UNTIL_HOLIDAY} hari lagi | ${DAYS_UNTIL_HOLIDAY} days left"
            fi
            MESSAGE="☀️ *LIBUR JEPANG ${DAYS_TEXT}!*

🎌 ${NAME_ID} | ${NAME_EN}
📛 ${NAME_JA}
📝 ${NAME_EN}

Semoga rencanamu lancar! / Have a great plan!"
        fi
        ;;
    12)
        if [ "${DAY_TYPE}" = "h" ]; then
            MESSAGE="🌤️ *LIBUR NASIONAL JEPANG - JAPAN NATIONAL HOLIDAY*

Hari ini: **${NAME_ID}** (${NAME_JA})
Today: **${NAME_EN}** (${NAME_JA})

Tetap semangat walaupun libur! / Enjoy your day! 💪"
        else
            # H-1, H-2, H-3
            if [ ${DAYS_UNTIL_HOLIDAY} -eq 1 ]; then
                DAYS_TEXT="Besok | Tomorrow"
            elif [ ${DAYS_UNTIL_HOLIDAY} -eq 2 ]; then
                DAYS_TEXT="Lusa | In 2 days"
            else
                DAYS_TEXT="${DAYS_UNTIL_HOLIDAY} hari lagi | ${DAYS_UNTIL_HOLIDAY} days left"
            fi
            MESSAGE="🌤️ *REMINDER LIBUR JEPANG ${DAYS_TEXT}*

${DAYS_TEXT}: **${NAME_ID}** | **${NAME_EN}**
🇯🇵 ${NAME_JA}

Happy holiday weekend! 🎉"
        fi
        ;;
    15)
        if [ "${DAY_TYPE}" = "h" ]; then
            MESSAGE="🌥️ *SELAMAT HARI LIBUR - HAPPY HOLIDAY*

Merayakan **${NAME_ID}** 🇯🇵 | Celebrating **${NAME_EN}** 🇯🇵

${NAME_JA} - ${NAME_EN}

Enjoy your day! 🎌"
        else
            # H-1, H-2, H-3
            if [ ${DAYS_UNTIL_HOLIDAY} -eq 1 ]; then
                DAYS_TEXT="Besok"
            elif [ ${DAYS_UNTIL_HOLIDAY} -eq 2 ]; then
                DAYS_TEXT="Lusa"
            else
                DAYS_TEXT="${DAYS_UNTIL_HOLIDAY} hari lagi"
            fi
            MESSAGE="🌥️ *LIBUR JEPANG ${DAYS_TEXT}*

${DAYS_TEXT} libur: **${NAME_ID}** (${NAME_EN})
${DAYS_TEXT} is a holiday: **${NAME_EN}** (${NAME_ID})

Siapin rencana liburnya! / Get ready for the holiday! 🎌"
        fi
        ;;
    18)
        if [ "${DAY_TYPE}" = "h" ]; then
            MESSAGE="🌆 *LIBUR JEPANG HARI INI - JAPAN HOLIDAY TODAY*

**${NAME_ID}** (${NAME_JA}) | **${NAME_EN}** (${NAME_JA})

Semoga harimu menyenangkan! / Have a wonderful day! 🎉🇯🇵"
        else
            # H-1, H-2, H-3
            if [ ${DAYS_UNTIL_HOLIDAY} -eq 1 ]; then
                DAYS_TEXT="Besok | Tomorrow"
            elif [ ${DAYS_UNTIL_HOLIDAY} -eq 2 ]; then
                DAYS_TEXT="Lusa | In 2 days"
            else
                DAYS_TEXT="${DAYS_UNTIL_HOLIDAY} hari lagi | ${DAYS_UNTIL_HOLIDAY} days left"
            fi
            MESSAGE="🌆 *PENGINGAT MALAM - EVENING REMINDER*

${DAYS_TEXT} libur Jepang: **${NAME_ID}** 🇯🇵
${DAYS_TEXT} is Japan holiday: **${NAME_EN}** 🇯🇵

${NAME_JA} (${NAME_EN})

Selamat menikmati libur! / Enjoy the holiday! 🎉"
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
