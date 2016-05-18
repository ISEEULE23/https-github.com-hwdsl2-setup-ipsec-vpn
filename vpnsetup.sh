#!/bin/sh
#
# Script for automatic setup of an IPsec/L2TP VPN server on Ubuntu LTS and Debian 8.
# Works on dedicated servers and any KVM- or Xen-based Virtual Private Server (VPS).
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS MEANT TO BE RUN
# ON YOUR DEDICATED SERVER OR VPS!
#
# Copyright (C) 2014-2016 Lin Song
# Based on the work of Thomas Sarlandie (Copyright 2012)
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

# =====================================================

# Define your own values for these variables
# - IPsec Pre-Shared Key, VPN Username and Password
# - All values MUST be quoted using 'single quotes'
# - DO NOT use these characters inside values:  \ " '

IPSEC_PSK="$VPNSETUP_IPSEC_PSK"
VPN_USER="$VPNSETUP_USERNAME"
VPN_PASSWORD="$VPNSETUP_PASSWORD"

# Important Notes:   https://git.io/vpnnotes
# Setup VPN Clients: https://git.io/vpnclients

# =====================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [ "$(uname)" = "Darwin" ]; then
  echo 'DO NOT run this script on your Mac! It should only be used on a server.'
  exit 1
fi

os_type="$(lsb_release -si 2>/dev/null)"
if [ "$os_type" != "Ubuntu" ] && [ "$os_type" != "Debian" ]; then
  echo "This script only supports Ubuntu/Debian."
  exit 1
fi

if [ -f /proc/user_beancounters ]; then
  echo "This script does NOT support OpenVZ VPS."
  echo "Try: https://github.com/Nyr/openvpn-install"
  exit 1
fi

if [ "$(id -u)" != 0 ]; then
  echo "Script must be run as root. Try 'sudo sh $0'"
  exit 1
fi

if [ ! -f /sys/class/net/eth0/operstate ]; then
  echo "Network interface 'eth0' is not available. Aborting."
  echo
  echo "Run 'cat /proc/net/dev' to find the name of the active network interface,"
  echo "then search and replace ALL 'eth0' and 'eth+' in this script with that name."
  exit 1
fi

if [ -z "$IPSEC_PSK" ] && [ -z "$VPN_USER" ] && [ -z "$VPN_PASSWORD" ]; then
  IPSEC_PSK="$(< /dev/urandom tr -dc 'A-HJ-NPR-Za-km-z2-9' | head -c 16)"
  VPN_USER=vpnuser
  VPN_PASSWORD="$(< /dev/urandom tr -dc 'A-HJ-NPR-Za-km-z2-9' | head -c 16)"
fi

if [ -z "$IPSEC_PSK" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASSWORD" ]; then
  echo "VPN credentials cannot be empty. Edit the script and re-enter them."
  exit 1
fi

echo "VPN setup in progress... Please be patient."

# Create and change to working dir
mkdir -p /opt/src
cd /opt/src || exit 1

# Update package index
export DEBIAN_FRONTEND=noninteractive
apt-get -yqq update

# Make sure basic commands exist
apt-get -yqq install wget dnsutils openssl
apt-get -yqq install iproute gawk grep sed net-tools

if [ "$(sed 's/\..*//' /etc/debian_version)" = "7" ]; then
  echo
  echo 'IMPORTANT: Workaround required for Debian 7 (Wheezy).'
  echo 'First, run the script at: https://git.io/vpndebian7'
  echo 'If not already done so, press Ctrl-C to interrupt.'
  echo
  echo 'Pausing for 30 seconds ...'
  sleep 30
fi

echo
echo 'Trying to find Public/Private IP of this server...'
echo
echo 'In case the script hangs here for more than a few minutes,'
echo 'use Ctrl-C to interrupt. Then edit it and manually enter IPs.'
echo

# In Amazon EC2, these two variables will be retrieved from metadata.
# For all other servers, replace them with actual IPs or comment out.
# If your server only has a public IP, put that IP on both lines.
PUBLIC_IP=$(wget --retry-connrefused -t 3 -T 15 -qO- 'http://169.254.169.254/latest/meta-data/public-ipv4')
PRIVATE_IP=$(wget --retry-connrefused -t 3 -T 15 -qO- 'http://169.254.169.254/latest/meta-data/local-ipv4')

# Try to find IPs for non-EC2 servers
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
[ -z "$PRIVATE_IP" ] && PRIVATE_IP=$(ip -4 route get 1 | awk '{print $NF;exit}')
[ -z "$PRIVATE_IP" ] && PRIVATE_IP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

# Check IPs for correct format
IP_REGEX="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
if ! printf %s "$PUBLIC_IP" | grep -Eq "$IP_REGEX"; then
  echo "Cannot find valid public IP. Edit the script and manually enter IPs."
  exit 1
fi
if ! printf %s "$PRIVATE_IP" | grep -Eq "$IP_REGEX"; then
  echo "Cannot find valid private IP. Edit the script and manually enter IPs."
  exit 1
fi

# Install necessary packages
apt-get -yqq install libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
        libcap-ng-dev libcap-ng-utils libselinux1-dev \
        libcurl4-nss-dev flex bison gcc make \
        libunbound-dev libnss3-tools libevent-dev
apt-get -yqq --no-install-recommends install xmlto
apt-get -yqq install xl2tpd

# Install Fail2Ban to protect SSH
apt-get -yqq install fail2ban

# Compile and install Libreswan
SWAN_VER=3.17
SWAN_FILE="libreswan-${SWAN_VER}.tar.gz"
SWAN_URL="https://download.libreswan.org/$SWAN_FILE"
wget -t 3 -T 30 -nv -O "$SWAN_FILE" "$SWAN_URL"
[ "$?" != "0" ] && { echo "Cannot download Libreswan source. Aborting."; exit 1; }
/bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
tar xzf "$SWAN_FILE" && /bin/rm -f "$SWAN_FILE"
cd "libreswan-$SWAN_VER" || { echo "Cannot enter Libreswan source dir. Aborting."; exit 1; }
# Workaround for Libreswan compile issues
cat > Makefile.inc.local <<EOF
WERROR_CFLAGS =
EOF
make -s programs && make -s install

# Verify the install
/usr/local/sbin/ipsec --version 2>/dev/null | grep -qs "$SWAN_VER"
[ "$?" != "0" ] && { echo; echo "Libreswan $SWAN_VER failed to build. Aborting."; exit 1; }

# Create IPsec (Libreswan) config
SYS_DT="$(date +%Y-%m-%d-%H:%M:%S)"
/bin/cp -f /etc/ipsec.conf "/etc/ipsec.conf.old-$SYS_DT" 2>/dev/null
cat > /etc/ipsec.conf <<EOF
version 2.0

config setup
  virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!192.168.42.0/23
  protostack=netkey
  nhelpers=0
  interfaces=%defaultroute
  uniqueids=no

conn shared
  left=$PRIVATE_IP
  leftid=$PUBLIC_IP
  right=%any
  forceencaps=yes
  authby=secret
  pfs=no
  rekey=no
  keyingtries=5
  dpddelay=30
  dpdtimeout=120
  dpdaction=clear

conn l2tp-psk
  auto=add
  leftsubnet=$PRIVATE_IP/32
  leftnexthop=%defaultroute
  leftprotoport=17/1701
  rightprotoport=17/%any
  rightsubnetwithin=0.0.0.0/0
  type=transport
  auth=esp
  ike=3des-sha1,aes-sha1
  phase2alg=3des-sha1,aes-sha1
  also=shared

conn xauth-psk
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=192.168.43.10-192.168.43.250
  modecfgdns1=8.8.8.8
  modecfgdns2=8.8.4.4
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  xauthby=file
  ike-frag=yes
  ikev2=never
  cisco-unity=yes
  also=shared
EOF

# Specify IPsec PSK
/bin/cp -f /etc/ipsec.secrets "/etc/ipsec.secrets.old-$SYS_DT" 2>/dev/null
cat > /etc/ipsec.secrets <<EOF
$PUBLIC_IP  %any  : PSK "$IPSEC_PSK"
EOF

# Create xl2tpd config
/bin/cp -f /etc/xl2tpd/xl2tpd.conf "/etc/xl2tpd/xl2tpd.conf.old-$SYS_DT" 2>/dev/null
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701

[lns default]
ip range = 192.168.42.10-192.168.42.250
local ip = 192.168.42.1
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

# Set xl2tpd options
/bin/cp -f /etc/ppp/options.xl2tpd "/etc/ppp/options.xl2tpd.old-$SYS_DT" 2>/dev/null
cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1280
mru 1280
lock
lcp-echo-failure 10
lcp-echo-interval 60
connect-delay 5000
EOF

# Create VPN credentials
/bin/cp -f /etc/ppp/chap-secrets "/etc/ppp/chap-secrets.old-$SYS_DT" 2>/dev/null
cat > /etc/ppp/chap-secrets <<EOF
# Secrets for authentication using CHAP
# client  server  secret  IP addresses
"$VPN_USER" l2tpd "$VPN_PASSWORD" *
EOF

/bin/cp -f /etc/ipsec.d/passwd "/etc/ipsec.d/passwd.old-$SYS_DT" 2>/dev/null
VPN_PASSWORD_ENC=$(openssl passwd -1 "$VPN_PASSWORD")
echo "${VPN_USER}:${VPN_PASSWORD_ENC}:xauth-psk" > /etc/ipsec.d/passwd

# Update sysctl settings
if ! grep -qs "hwdsl2 VPN script" /etc/sysctl.conf; then
/bin/cp -f /etc/sysctl.conf "/etc/sysctl.conf.old-$SYS_DT" 2>/dev/null
cat >> /etc/sysctl.conf <<EOF

# Added by hwdsl2 VPN script
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.rp_filter = 0
net.ipv4.conf.eth0.rp_filter = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
EOF
fi

# Create basic IPTables rules. First check for existing rules.
# - If IPTables is "empty", simply write out the new rules.
# - If *not* empty, insert new rules and save them with existing ones.
if ! grep -qs "hwdsl2 VPN script" /etc/iptables.rules; then
/bin/cp -f /etc/iptables.rules "/etc/iptables.rules.old-$SYS_DT" 2>/dev/null
service fail2ban stop >/dev/null 2>&1
if [ "$(iptables-save | grep -c '^\-')" = "0" ]; then
cat > /etc/iptables.rules <<EOF
# Added by hwdsl2 VPN script
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 -j REJECT
-A INPUT -p icmp -j ACCEPT
-A INPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p udp -m multiport --dports 500,4500 -j ACCEPT
-A INPUT -p udp --dport 1701 -m policy --dir in --pol ipsec -j ACCEPT
-A INPUT -p udp --dport 1701 -j DROP
-A INPUT -j DROP
-A FORWARD -m conntrack --ctstate INVALID -j DROP
-A FORWARD -i eth+ -o ppp+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i ppp+ -o eth+ -j ACCEPT
-A FORWARD -i eth+ -d 192.168.43.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s 192.168.43.0/24 -o eth+ -j ACCEPT
# To allow traffic between VPN clients themselves, uncomment these lines:
# -A FORWARD -i ppp+ -o ppp+ -s 192.168.42.0/24 -d 192.168.42.0/24 -j ACCEPT
# -A FORWARD -s 192.168.43.0/24 -d 192.168.43.0/24 -j ACCEPT
-A FORWARD -j DROP
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 192.168.42.0/24 -o eth+ -j SNAT --to-source "$PRIVATE_IP"
-A POSTROUTING -s 192.168.43.0/24 -o eth+ -m policy --dir out --pol none -j SNAT --to-source "$PRIVATE_IP"
COMMIT
EOF

else

iptables -I INPUT 1 -p udp -m multiport --dports 500,4500 -j ACCEPT
iptables -I INPUT 2 -p udp --dport 1701 -m policy --dir in --pol ipsec -j ACCEPT
iptables -I INPUT 3 -p udp --dport 1701 -j DROP
iptables -I FORWARD 1 -m conntrack --ctstate INVALID -j DROP
iptables -I FORWARD 2 -i eth+ -o ppp+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 3 -i ppp+ -o eth+ -j ACCEPT
iptables -I FORWARD 4 -i eth+ -d 192.168.43.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 5 -s 192.168.43.0/24 -o eth+ -j ACCEPT
# iptables -I FORWARD 6 -i ppp+ -o ppp+ -s 192.168.42.0/24 -d 192.168.42.0/24 -j ACCEPT
# iptables -I FORWARD 7 -s 192.168.43.0/24 -d 192.168.43.0/24 -j ACCEPT
iptables -A FORWARD -j DROP
iptables -t nat -I POSTROUTING -s 192.168.43.0/24 -o eth+ -m policy --dir out --pol none -j SNAT --to-source "$PRIVATE_IP"
iptables -t nat -I POSTROUTING -s 192.168.42.0/24 -o eth+ -j SNAT --to-source "$PRIVATE_IP"

echo "# Modified by hwdsl2 VPN script" > /etc/iptables.rules
iptables-save >> /etc/iptables.rules
fi
# Update rules for iptables-persistent
if [ -f /etc/iptables/rules.v4 ]; then
/bin/cp -f /etc/iptables/rules.v4 "/etc/iptables/rules.v4.old-$SYS_DT"
/bin/cp -f /etc/iptables.rules /etc/iptables/rules.v4
fi
fi

# Create basic IPv6 rules
if ! grep -qs "hwdsl2 VPN script" /etc/ip6tables.rules; then
/bin/cp -f /etc/ip6tables.rules "/etc/ip6tables.rules.old-$SYS_DT" 2>/dev/null
cat > /etc/ip6tables.rules <<EOF
# Added by hwdsl2 VPN script
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -m rt --rt-type 0 -j DROP
-A INPUT -s fe80::/10 -j ACCEPT
-A INPUT -p ipv6-icmp -j ACCEPT
-A INPUT -j DROP
COMMIT
EOF
if [ -f /etc/iptables/rules.v6 ]; then
/bin/cp -f /etc/iptables/rules.v6 "/etc/iptables/rules.v6.old-$SYS_DT"
/bin/cp -f /etc/ip6tables.rules /etc/iptables/rules.v6
fi
fi

# Load IPTables rules at system boot
cat > /etc/network/if-pre-up.d/iptablesload <<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
EOF

cat > /etc/network/if-pre-up.d/ip6tablesload <<EOF
#!/bin/sh
ip6tables-restore < /etc/ip6tables.rules
exit 0
EOF

# Start services at boot
if ! grep -qs "hwdsl2 VPN script" /etc/rc.local; then
/bin/cp -f /etc/rc.local "/etc/rc.local.old-$SYS_DT" 2>/dev/null
sed --follow-symlinks -i -e '/^exit 0/d' /etc/rc.local
cat >> /etc/rc.local <<EOF

# Added by hwdsl2 VPN script
service fail2ban restart || /bin/true
service ipsec start
service xl2tpd start
echo 1 > /proc/sys/net/ipv4/ip_forward
exit 0
EOF
fi

# Initialize Libreswan DB
if [ ! -f /etc/ipsec.d/cert8.db ] ; then
   echo > /var/tmp/libreswan-nss-pwd
   certutil -N -f /var/tmp/libreswan-nss-pwd -d /etc/ipsec.d
   /bin/rm -f /var/tmp/libreswan-nss-pwd
fi

# Reload sysctl.conf
sysctl -q -p

# Update file attributes
chmod +x /etc/rc.local
chmod +x /etc/network/if-pre-up.d/iptablesload
chmod +x /etc/network/if-pre-up.d/ip6tablesload
chmod 600 /etc/ipsec.secrets* /etc/ppp/chap-secrets* /etc/ipsec.d/passwd*

# Apply new IPTables rules
iptables-restore < /etc/iptables.rules
ip6tables-restore < /etc/ip6tables.rules >/dev/null 2>&1

# Restart services
service fail2ban restart
service ipsec restart
service xl2tpd restart

echo
echo '================================================'
echo
echo 'IPsec/L2TP VPN server setup is complete!'
echo
echo 'Connect to your new VPN with these details:'
echo
echo "Server IP: $PUBLIC_IP"
echo "IPsec PSK: $IPSEC_PSK"
echo "Username: $VPN_USER"
echo "Password: $VPN_PASSWORD"
echo
echo "Write these down. You'll need them to connect! "
echo
echo 'Important Notes:   https://git.io/vpnnotes'
echo 'Setup VPN Clients: https://git.io/vpnclients'
echo
echo '================================================'
echo

exit 0
