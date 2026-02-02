# Reminder Libur Jepang 🇯🇵

Reminder otomatis untuk libur nasional Jepang tahun 2026 via WhatsApp.

## Fitur

- ✅ Cek otomatis libur nasional Jepang 2026
- ✅ Pengingat H-1 (sehari sebelum libur)
- ✅ Pengingat H-2 (dari Sabtu ke Senin libur)
- ✅ Pengingat H (hari libur)
- ✅ Smart weekend logic:
  - **Sabtu/Minggu**: tidak kirim pesan "hari ini libur"
  - **Jumat**: tidak kirim pengingat untuk Sabtu/Minggu (weekend)
  - **Sabtu**: kirim pengingat kalau Senin libur (H-2)
  - **Minggu**: kirim pengingat kalau Senin libur (H-1)
- ✅ Pengiriman jam 06:00, 09:00, 12:00, 15:00, 18:00
- ✅ Support multiple recipients
- ✅ Pesan bilingual (Indonesia + Inggris)
- ✅ Menggunakan WAHA (WhatsApp HTTP API)
- ✅ Logging otomatis
- ✅ Test mode untuk debugging

## Instalasi

### Prasyarat

```bash
# Install jq (required for JSON handling)
sudo apt install jq
```

### Setup

1. Clone repository ini:
```bash
cd /home/agungdh/repo/reminder-libur-jepang
```

2. Copy file `.env.example` ke `.env`:
```bash
cp .env.example .env
```

3. Edit `.env` dan isi dengan konfigurasi WAHA kamu:
```bash
WAHA_URL="https://your-waha-host.com"
WAHA_API_KEY="your_api_key_here"

# Multiple recipients - pisahkan dengan spasi
WAHA_CHATS="628xxxxxxxxxx@c.us 628yyyyyyyyyy@c.us"
```

4. Buat script executable:
```bash
chmod +x send-reminder.sh
```

5. Install crontab:
```bash
crontab -e
# Copy isi dari crontab.txt
```

## Jadwal Libur Jepang 2026

| Tanggal | Hari | Nama Libur (Indonesia) | Nama Libur (Inggris) |
|---------|------|----------------------|---------------------|
| 1 Jan | Kamis | Tahun Baru | New Year's Day |
| 12 Jan | Senin | Hari Dewasa | Coming-of-Age Day |
| 11 Feb | Rabu | Hari Pendirian Negara | National Foundation Day |
| 23 Feb | Senin | Ulang Tahun Kaisar | The Emperor's Birthday |
| 20 Mar | Jumat | Hari Vernal Equinox | Vernal Equinox Day |
| 29 Apr | Rabu | Hari Showa | Shōwa Day |
| 3 Mei | Minggu | Hari Konstitusi | Constitution Memorial Day |
| 4 Mei | Senin | Hari Hijau | Greenery Day |
| 5 Mei | Selasa | Hari Anak | Children's Day |
| 6 Mei | Rabu | Hari Libur Pengganti | Observed Holiday |
| 20 Jul | Senin | Hari Laut | Marine Day |
| 11 Agu | Selasa | Hari Gunung | Mountain Day |
| 21 Sep | Senin | Hari Menghormati Lansia | Respect for the Aged Day |
| 23 Sep | Rabu | Hari Autumn Equinox | Autumn Equinox Day |
| 12 Okt | Senin | Hari Olahraga | Sports Day |
| 3 Nov | Selasa | Hari Budaya | Culture Day |
| 23 Nov | Senin | Hari Thanksgiving Pekerja | Labor Thanksgiving Day |

**Golden Week 2026**: 29 April - 6 Mei (8 hari berturut-turut!)

## Testing

### Test mode dengan tanggal dan jam spesifik:

```bash
# Test pengingat H-1 New Year (31 Des, test besok libur)
TEST_DATE=2025-12-31 TEST_HOUR=6 ./send-reminder.sh

# Test hari H New Year
TEST_DATE=2026-01-01 TEST_HOUR=9 ./send-reminder.sh

# Test Golden Week
TEST_DATE=2026-04-28 TEST_HOUR=12 ./send-reminder.sh

# Test weekend logic (Sabtu, cek Senin libur)
TEST_DATE=2026-04-25 TEST_DOW=6 TEST_HOUR=6 ./send-reminder.sh

# Test weekend logic (Minggu, cek Senin libur)
TEST_DATE=2026-04-26 TEST_DOW=7 TEST_HOUR=6 ./send-reminder.sh
```

### Test jam yang tersedia (untuk message template berbeda):

### Test jam yang tersedia (untuk message template berbeda):

| Jam | Template |
|-----|----------|
| 06:00 | Morning (pagi) |
| 09:00 | Late morning |
| 12:00 | Midday |
| 15:00 | Afternoon |
| 18:00 | Evening |

### Test di .env:

```bash
# Tambahkan di .env untuk testing
TEST_DATE=2026-01-01
TEST_HOUR=6
```

## Logging

Log disimpan di folder `logs/` dengan format `reminder-YYYYMMDD.log`.

## Konfigurasi Environment Variables

| Variable | Required | Deskripsi |
|----------|----------|-----------|
| `WAHA_URL` | Yes | URL WAHA server |
| `WAHA_API_KEY` | Yes | API key WAHA |
| `WAHA_CHATS` | Yes | Nomor WhatsApp (bisa multiple, pisah spasi) |
| `TEST_DATE` | No | Tanggal test (format: YYYY-MM-DD) |
| `TEST_HOUR` | No | Jam test (6, 9, 12, 15, atau 18) |
| `TEST_DOW` | No | Day of week test (1=Senin, 7=Minggu) |

## Credits

- Terinspirasi dari [reminder-bangunin-my-prince](https://github.com/agungdh/reminder-bangunin-my-prince)
- Data libur dari [timeanddate.com](https://www.timeanddate.com/holidays/japan/2026)

## Lisensi

MIT
