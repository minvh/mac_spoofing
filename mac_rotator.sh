#!/bin/bash
# mac_rotator.sh - Menjajal beberapa MAC Address terotorisasi di macOS

INTERFACE="en0"
SSID="UKI-HOTSPOT"

# Lokasi utility airport bawaan macOS
AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

# Daftar MAC Address terotorisasi
MACS=(
  "06:4e:57:27:80:bb"
  "a6:9a:68:c6:01:8e"
  "d6:53:f6:84:44:2c"
)

echo "[*] Memulai rotasi MAC Address di macOS..."

for mac in "${MACS[@]}"; do
  echo "----------------------------------------"
  echo "[*] Mencoba MAC: $mac"

  # 1. Putuskan Wi-Fi sementara
  sudo "$AIRPORT" -z 2>/dev/null
  sleep 1

  # 2. Ubah MAC Address menggunakan perintah bawaan macOS (ether)
  sudo ifconfig $INTERFACE ether $mac

  # 3. Hubungkan kembali ke Wi-Fi target
  echo "[*] Menghubungkan ke SSID: $SSID..."
  networksetup -setairportnetwork $INTERFACE "$SSID"
  
  # Beri waktu beberapa detik untuk alokasi IP via DHCP
  echo "[*] Menunggu alokasi IP..."
  sleep 8

  # 4. Tes koneksi internet
  if curl -s --max-time 5 http://google.com > /dev/null; then
    echo "[+] Berhasil konek menggunakan MAC: $mac"
    exit 0
  fi
 
  echo "[-] Gagal konek dengan MAC: $mac"
  sleep 2
done

echo "----------------------------------------"
echo "[-] Semua MAC Address gagal diproses."
