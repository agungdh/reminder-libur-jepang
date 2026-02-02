#!/usr/bin/env python3
"""
Japanese Holiday Reminder Checker
Check if today or tomorrow is a Japanese holiday and send reminders via WAHA
"""

import json
import os
import sys
from datetime import date, datetime, timedelta

# Load environment variables
def load_env():
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    if not os.path.exists(env_file):
        print(f"Error: .env file not found at {env_file}")
        sys.exit(1)

    env = {}
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                env[key.strip()] = value.strip().strip('"')
    return env

# Load holidays data
def load_holidays():
    holidays_file = os.path.join(os.path.dirname(__file__), 'holidays.json')
    with open(holidays_file) as f:
        return json.load(f)

# Get holiday info for a date
def get_holiday(d: date) -> dict:
    holidays = load_holidays()
    date_str = d.strftime('%Y-%m-%d')
    return holidays.get(date_str)

# Generate message based on time and day type
def generate_message(holiday_info: dict, day_type: str, hour: int) -> str:
    name_id = holiday_info['name_id']
    name_ja = holiday_info['name_ja']
    name_en = holiday_info['name_en']

    if day_type == 'h-1':
        # Day before holiday messages
        messages = {
            6: f"🌅 *PENGINGAT LIBUR JEPANG*\n\nBesok libur nasional Jepang: **{name_id}** ({name_ja}) 🇯🇵\n\nJangan lupa persiapan ya!",
            9: f"☀️ *BESOK LIBUR JEPANG!*\n\n🎌 {name_id}\n📛 {name_ja}\n📝 {name_en}\n\nSemoga rencanamu lancar!",
            12: f"🌤️ *REMINDER H-1 LIBUR JEPANG*\n\nBesok: **{name_id}**\n🇯🇵 {name_ja}\n\nHappy holiday weekend! 🎉",
            15: f"🌥️ *H-1 LIBUR JEPANG*\n\nBesok libur: **{name_id}** ({name_en})\n\nSiapin rencana liburnya! 🎌",
            18: f"🌆 *PENGINGAT MALAM*\n\nBesok libur Jepang: **{name_id}** 🇯🇵\n\n{name_ja} ({name_en})\n\nSelamat menikmati libur! 🎉"
        }
    else:
        # Holiday day messages
        messages = {
            6: f"🌅 *SELAMAT LIBUR NASIONAL JEPANG!*\n\nHari ini: **{name_id}** 🇯🇵\n🎌 {name_ja}\n\nHappy holiday! 🎉",
            9: f"☀️ *HARI INI LIBUR JEPANG!*\n\n🎌 {name_id}\n📛 {name_ja}\n📝 {name_en}\n\nSelamat hari libur! 🇯🇵",
            12: f"🌤️ *LIBUR NASIONAL JEPANG*\n\nHari ini: **{name_id}** ({name_ja})\n\nTetap semangat walaupun libur! 💪",
            15: f"🌥️ *SELAMAT HARI LIBUR*\n\nMerayakan **{name_id}** 🇯🇵\n\n{name_ja} - {name_en}\n\nEnjoy your day! 🎌",
            18: f"🌆 *LIBUR JEPANG HARI INI*\n\n**{name_id}** ({name_ja})\n\nSemoga harimu menyenangkan! 🎉🇯🇵"
        }

    return messages.get(hour, f"Libur Jepang: {name_id} ({name_ja})")

def main():
    # Get current time
    now = datetime.now()
    current_hour = now.hour

    # Check if current hour is valid for reminders
    valid_hours = [6, 9, 12, 15, 18]
    if current_hour not in valid_hours:
        print(f"Current hour {current_hour} is not a valid reminder time")
        sys.exit(0)

    # Check today and tomorrow
    today = now.date()
    tomorrow = today + timedelta(days=1)

    holiday_today = get_holiday(today)
    holiday_tomorrow = get_holiday(tomorrow)

    message = None

    if holiday_tomorrow:
        # H-1 reminder
        message = generate_message(holiday_tomorrow, 'h-1', current_hour)
        print(f"[H-1] Tomorrow is {holiday_tomorrow['name_id']}")
    elif holiday_today:
        # H day reminder
        message = generate_message(holiday_today, 'h', current_hour)
        print(f"[H] Today is {holiday_today['name_id']}")
    else:
        print("No holiday today or tomorrow")
        sys.exit(0)

    # Print message for bash script to use
    print(f"MESSAGE:{message}")

if __name__ == '__main__':
    main()
