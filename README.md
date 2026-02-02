# Reminder Libur Jepang 🇯🇵

Reminder otomatis untuk libur nasional Jepang tahun 2026 via WhatsApp.

## Fitur

- ✅ Cek otomatis libur nasional Jepang 2026
- ✅ Pengingat H-1 (sehari sebelum libur)
- ✅ Pengingat H (hari libur)
- ✅ Pengiriman jam 06:00, 09:00, 12:00, 15:00, 18:00
- ✅ Menggunakan WAHA (WhatsApp HTTP API)
- ✅ Logging otomatis

## Instalasi

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
WAHA_CHATS="628xxxxxxxxxx@c.us"
WAHA_SESSION="default"
```

4. Buat script executable:
```bash
chmod +x send-reminder.sh
chmod +x check-holiday.py
```

5. Install crontab:
```bash
crontab -e
# Copy isi dari crontab.txt
```

## Jadwal Libur Jepang 2026

| Tanggal | Hari | Nama Libur (Indonesia) |
|---------|------|----------------------|
| 1 Jan | Kamis | Tahun Baru |
| 12 Jan | Senin | Hari Dewasa |
| 11 Feb | Rabu | Hari Pendirian Negara |
| 23 Feb | Senin | Ulang Tahun Kaisar |
| 20 Mar | Jumat | Hari Vernal Equinox |
| 29 Apr | Rabu | Hari Showa |
| 3 Mei | Minggu | Hari Konstitusi |
| 4 Mei | Senin | Hari Hijau |
| 5 Mei | Selasa | Hari Anak |
| 6 Mei | Rabu | Hari Libur Pengganti |
| 23 Jul | Kamis | Hari Laut |
| 11 Agu | Selasa | Hari Gunung |
| 21 Sep | Senin | Hari Menghormati Lansia |
| 23 Sep | Rabu | Hari Autumn Equinox |
| 12 Okt | Senin | Hari Olahraga |
| 3 Nov | Selasa | Hari Budaya |
| 23 Nov | Senin | Hari Thanksgiving Pekerja |

## Testing

Test manual dengan menjalankan:
```bash
./send-reminder.sh
```

## Logging

Log disimpan di folder `logs/` dengan format `reminder-YYYYMMDD.log`.

## Credits

Terinspirasi dari [reminder-bangunin-my-prince](https://github.com/agungdh/reminder-bangunin-my-prince)
