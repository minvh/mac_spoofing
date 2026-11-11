#!/bin/bash
INTERFACE="en0"

MY_IP=$(ipconfig getifaddr $INTERFACE)
ROUTER_IP=$(netstat -rn -f inet | grep 'default' | awk '{print $2}' | head -n 1)

# Dapatkan MAC Address milik Router dari tabel ARP
ROUTER_MAC=$(arp -a -i $INTERFACE | grep "($ROUTER_IP)" | awk '{print $4}')

echo "[*] IP Anda   : $MY_IP"
echo "[*] IP Router : $ROUTER_IP ($ROUTER_MAC)"
echo "[*] Memindai dan menyaring MAC Unik..."

# Ping sweep untuk memperbarui cache ARP
SUBNET=$(echo $MY_IP | cut -d. -f1-3)
for i in {1..254}; do
  ping -c 1 -W 150 $SUBNET.$i > /dev/null 2>&1 &
done
wait

echo -e "\n[+] Daftar MAC Address Klien Unik (Tanpa Router & Multicast):"
echo "---------------------------------------------------"

# Filter ARP: Abaikan IP Router, IP Multicast (224.x), IP Sendiri, dan MAC milik Router
arp -a -i $INTERFACE | grep -v "incomplete" | awk -v router_ip="$ROUTER_IP" -v router_mac="$ROUTER_MAC" -v myip="$MY_IP" -F '[()]' '{
  ip = $2
  split($3, a, " ")
  mac = a[2]

  # Normalisasi format MAC macOS (menambahkan 0 yang terpotong)
  split(mac, octets, ":")
  formatted_mac = ""
  for (i = 1; i <= length(octets); i++) {
    if (length(octets[i]) == 1) octets[i] = "0" octets[i]
    formatted_mac = (i == 1) ? octets[i] : formatted_mac ":" octets[i]
  }

  # Filter: Bukan Router, Bukan IP Sendiri, Bukan IP Multicast (224.x), dan Bukan MAC Router
  if (ip != router_ip && ip != myip && ip !~ /^224\./ && formatted_mac != router_mac && formatted_mac != "ff:ff:ff:ff:ff:ff") {
    print formatted_mac
  }
}' | sort -u

echo "---------------------------------------------------"