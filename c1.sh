#!/bin/bash
#
# Script for automatic setup of an IPsec VPN server on CentOS/RHEL,
# Rocky Linux and AlmaLinux
# Works on any dedicated server or virtual private server (VPS)
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC!
#
# The latest version of this script is available at:
# https://github.com/hwdsl2/setup-ipsec-vpn
#
# Copyright (C) 2015-2021 Lin Song <linsongui@gmail.com>
# Based on the work of Thomas Sarlandie (Copyright 2012)
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

# =====================================================

# Define your own values for these variables
# - IPsec pre-shared key, VPN username and password
# - All values MUST be placed inside 'single quotes'
# - DO NOT use these special characters within values: \ " '

YOUR_IPSEC_PSK=''
YOUR_USERNAME=''
YOUR_PASSWORD=''

# Important notes:   https://git.io/vpnnotes
# Setup VPN clients: https://git.io/vpnclients
# IKEv2 guide:       https://git.io/ikev2

# =====================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SYS_DT=$(date +%F-%T | tr ':' '_')

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'yum install' failed."; }
conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
bigecho() { echo "## $1"; }

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

check_root() {
  if [ "$(id -u)" != 0 ]; then
    exiterr "Script must be run as root. Try 'sudo bash $0'"
  fi
}

check_vz() {
  if [ -f /proc/user_beancounters ]; then
    exiterr "OpenVZ VPS is not supported."
  fi
}

check_os() {
  os_type=centos
  os_arch=$(uname -m | tr -dc 'A-Za-z0-9_-')
  rh_file="/etc/redhat-release"
  if grep -qs "Red Hat" "$rh_file"; then
    os_type=rhel
  fi
  if grep -qs "release 7" "$rh_file"; then
    os_ver=7
  elif grep -qs "release 8" "$rh_file"; then
    os_ver=8
    grep -qi stream "$rh_file" && os_ver=8s
    grep -qi rocky "$rh_file" && os_type=rocky
    grep -qi alma "$rh_file" && os_type=alma
  else
    exiterr "This script only supports CentOS/RHEL 7/8, Rocky Linux and AlmaLinux."
  fi
}

check_iface() {
  def_iface=$(route 2>/dev/null | grep -m 1 '^default' | grep -o '[^ ]*$')
  [ -z "$def_iface" ] && def_iface=$(ip -4 route list 0/0 2>/dev/null | grep -m 1 -Po '(?<=dev )(\S+)')
  def_state=$(cat "/sys/class/net/$def_iface/operstate" 2>/dev/null)
  if [ -n "$def_state" ] && [ "$def_state" != "down" ]; then
    case $def_iface in
      wl*)
        exiterr "Wireless interface '$def_iface' detected. DO NOT run this script on your PC or Mac!"
        ;;
    esac
    NET_IFACE="$def_iface"
  else
    eth0_state=$(cat "/sys/class/net/eth0/operstate" 2>/dev/null)
    if [ -z "$eth0_state" ] || [ "$eth0_state" = "down" ]; then
      exiterr "Could not detect the default network interface."
    fi
    NET_IFACE=eth0
  fi
}

check_creds() {
  [ -n "$YOUR_IPSEC_PSK" ] && VPN_IPSEC_PSK="$YOUR_IPSEC_PSK"
  [ -n "$YOUR_USERNAME" ] && VPN_USER="$YOUR_USERNAME"
  [ -n "$YOUR_PASSWORD" ] && VPN_PASSWORD="$YOUR_PASSWORD"

  if [ -z "$VPN_IPSEC_PSK" ] && [ -z "$VPN_USER" ] && [ -z "$VPN_PASSWORD" ]; then
    bigecho "VPN credentials not set by user. Generating random PSK and password..."
    VPN_IPSEC_PSK=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' </dev/urandom 2>/dev/null | head -c 20)
    VPN_USER=vpnuser
    VPN_PASSWORD=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' </dev/urandom 2>/dev/null | head -c 16)
  fi

  if [ -z "$VPN_IPSEC_PSK" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASSWORD" ]; then
    exiterr "All VPN credentials must be specified. Edit the script and re-enter them."
  fi

  if printf '%s' "$VPN_IPSEC_PSK $VPN_USER $VPN_PASSWORD" | LC_ALL=C grep -q '[^ -~]\+'; then
    exiterr "VPN credentials must not contain non-ASCII characters."
  fi

  case "$VPN_IPSEC_PSK $VPN_USER $VPN_PASSWORD" in
    *[\\\"\']*)
      exiterr "VPN credentials must not contain these special characters: \\ \" '"
      ;;
  esac
}

check_dns() {
  if { [ -n "$VPN_DNS_SRV1" ] && ! check_ip "$VPN_DNS_SRV1"; } \
    || { [ -n "$VPN_DNS_SRV2" ] && ! check_ip "$VPN_DNS_SRV2"; } then
    exiterr "The DNS server specified is invalid."
  fi
}

start_setup() {
  bigecho "VPN setup in progress... Please be patient."
  # shellcheck disable=SC2154
  trap 'dlo=$dl;dl=$LINENO' DEBUG 2>/dev/null
  trap 'finish $? $((dlo+1))' EXIT
  mkdir -p /opt/src
  cd /opt/src || exit 1
}

install_setup_pkgs() {
  bigecho "Installing packages required for setup..."
  (
    set -x
    yum -y -q install wget bind-utils openssl tar \
      iptables iproute gawk grep sed net-tools >/dev/null
  ) || exiterr2
}

detect_ip() {
  bigecho "Trying to auto discover IP of this server..."
  public_ip=${VPN_PUBLIC_IP:-''}
  check_ip "$public_ip" || public_ip=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
  check_ip "$public_ip" || public_ip=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
  check_ip "$public_ip" || exiterr "Cannot detect this server's public IP. Define it as variable 'VPN_PUBLIC_IP' and re-run this script."
}

add_epel_repo() {
  bigecho "Adding the EPEL repository..."
  epel_url="https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm"
  (
    set -x
    yum -y -q install epel-release >/dev/null 2>&1 || yum -y -q install "$epel_url" >/dev/null
  ) || exiterr2
}

install_vpn_pkgs_1() {
  bigecho "Installing packages required for the VPN..."
  erp="--enablerepo"
  rp1="$erp=epel"
  rp2="$erp=*server-*optional*"
  rp3="$erp=*releases-optional*"
  rp4="$erp=[Pp]ower[Tt]ools"
  [ "$os_type" = "rhel" ] && rp4="$erp=codeready-builder-for-rhel-8-*"

  (
    set -x
    yum -y -q install nss-devel nspr-devel pkgconfig pam-devel \
      libcap-ng-devel libselinux-devel curl-devel nss-tools \
      flex bison gcc make util-linux ppp >/dev/null
  ) || exiterr2
}

install_vpn_pkgs_2() {
  (
    set -x
    yum "$rp1" -y -q install xl2tpd >/dev/null 2>&1
  ) || exiterr2
}

install_vpn_pkgs_3() {
  use_nft=0
  p1=systemd-devel
  p2=libevent-devel
  p3=fipscheck-devel
  p4=iptables-services
  if [ "$os_ver" = "7" ]; then
    (
      set -x
      yum "$rp2" "$rp3" -y -q install $p1 $p2 $p3 $p4 >/dev/null
    ) || exiterr2
  else
    (
      set -x
      yum "$rp4" -y -q install $p1 $p2 $p3 >/dev/null
    ) || exiterr2
    if systemctl is-active --quiet firewalld \
      || systemctl is-active --quiet nftables \
      || grep -qs "hwdsl2 VPN script" /etc/sysconfig/nftables.conf; then
      use_nft=1
      p4=nftables
    fi
    (
      set -x
      yum -y -q install $p4 >/dev/null
    ) || exiterr2
  fi
}

install_fail2ban() {
  bigecho "Installing Fail2Ban to protect SSH..."
  (
    set -x
    yum "$rp1" -y -q install fail2ban >/dev/null
  ) || exiterr2
}

get_ikev2_script() {
  bigecho "Downloading IKEv2 script..."
  ikev2_url="https://github.com/hwdsl2/setup-ipsec-vpn/raw/master/extras/ikev2setup.sh"
  (
    set -x
    wget -t 3 -T 30 -q -O ikev2.sh "$ikev2_url"
  ) || /bin/rm -f ikev2.sh
  [ -s ikev2.sh ] && chmod +x ikev2.sh && ln -s /opt/src/ikev2.sh /usr/bin 2>/dev/null
}

check_libreswan() {
  SWAN_VER=4.5
  ipsec_ver=$(/usr/local/sbin/ipsec --version 2>/dev/null)
  swan_ver_old=$(printf '%s' "$ipsec_ver" | sed -e 's/.*Libreswan U\?//' -e 's/\( (\|\/K\).*//')
  [ "$swan_ver_old" = "$SWAN_VER" ]
}

get_libreswan() {
  if ! check_libreswan; then
    bigecho "Downloading Libreswan..."
    swan_file="libreswan-$SWAN_VER.tar.gz"
    swan_url1="https://github.com/libreswan/libreswan/archive/v$SWAN_VER.tar.gz"
    swan_url2="https://download.libreswan.org/$swan_file"
    (
      set -x
      wget -t 3 -T 30 -q -O "$swan_file" "$swan_url1" || wget -t 3 -T 30 -q -O "$swan_file" "$swan_url2"
    ) || exit 1
    /bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
    tar xzf "$swan_file" && /bin/rm -f "$swan_file"
  else
    bigecho "Libreswan $SWAN_VER is already installed, skipping..."
  fi
}

install_libreswan() {
  if ! check_libreswan; then
    bigecho "Compiling and installing Libreswan, please wait..."
    cd "libreswan-$SWAN_VER" || exit 1
cat > Makefile.inc.local <<'EOF'
WERROR_CFLAGS=-w -s
USE_DNSSEC=false
USE_DH2=true
USE_NSS_KDF=false
FINALNSSDIR=/etc/ipsec.d
EOF
    if ! grep -qs IFLA_XFRM_LINK /usr/include/linux/if_link.h; then
      echo "USE_XFRM_INTERFACE_IFLA_HEADER=true" >> Makefile.inc.local
    fi
    NPROCS=$(grep -c ^processor /proc/cpuinfo)
    [ -z "$NPROCS" ] && NPROCS=1
    (
      set -x
      make "-j$((NPROCS+1))" -s base >/dev/null && make -s install-base >/dev/null
    )

    cd /opt/src || exit 1
    /bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
    if ! /usr/local/sbin/ipsec --version 2>/dev/null | grep -qF "$SWAN_VER"; then
      exiterr "Libreswan $SWAN_VER failed to build."
    fi
  fi
}

create_vpn_config() {
  bigecho "Creating VPN configuration..."

  L2TP_NET=${VPN_L2TP_NET:-'192.168.42.0/24'}
  L2TP_LOCAL=${VPN_L2TP_LOCAL:-'192.168.42.1'}
  L2TP_POOL=${VPN_L2TP_POOL:-'192.168.42.10-192.168.42.250'}
  XAUTH_NET=${VPN_XAUTH_NET:-'192.168.43.0/24'}
  XAUTH_POOL=${VPN_XAUTH_POOL:-'192.168.43.10-192.168.43.250'}
  DNS_SRV1=${VPN_DNS_SRV1:-'8.8.8.8'}
  DNS_SRV2=${VPN_DNS_SRV2:-'8.8.4.4'}
  DNS_SRVS="\"$DNS_SRV1 $DNS_SRV2\""
  [ -n "$VPN_DNS_SRV1" ] && [ -z "$VPN_DNS_SRV2" ] && DNS_SRVS="$DNS_SRV1"

  # Create IPsec config
  conf_bk "/etc/ipsec.conf"
cat > /etc/ipsec.conf <<EOF
version 2.0

config setup
  virtual-private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!$L2TP_NET,%v4:!$XAUTH_NET
  uniqueids=no

conn shared
  left=%defaultroute
  leftid=$public_ip
  right=%any
  encapsulation=yes
  authby=secret
  pfs=no
  rekey=no
  keyingtries=5
  dpddelay=30
  dpdtimeout=120
  dpdaction=clear
  ikev2=never
  ike=aes256-sha2,aes128-sha2,aes256-sha1,aes128-sha1,aes256-sha2;modp1024,aes128-sha1;modp1024
  phase2alg=aes_gcm-null,aes128-sha1,aes256-sha1,aes256-sha2_512,aes128-sha2,aes256-sha2
  ikelifetime=24h
  salifetime=24h
  sha2-truncbug=no

conn l2tp-psk
  auto=add
  leftprotoport=17/1701
  rightprotoport=17/%any
  type=transport
  also=shared

conn xauth-psk
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=$XAUTH_POOL
  modecfgdns=$DNS_SRVS
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  cisco-unity=yes
  also=shared

include /etc/ipsec.d/*.conf
EOF

  # Specify IPsec PSK
  conf_bk "/etc/ipsec.secrets"
cat > /etc/ipsec.secrets <<EOF
%any  %any  : PSK "$VPN_IPSEC_PSK"
EOF

  # Create xl2tpd config
  conf_bk "/etc/xl2tpd/xl2tpd.conf"
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701

[lns default]
ip range = $L2TP_POOL
local ip = $L2TP_LOCAL
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

  # Set xl2tpd options
  conf_bk "/etc/ppp/options.xl2tpd"
cat > /etc/ppp/options.xl2tpd <<EOF
+mschap-v2
ipcp-accept-local
ipcp-accept-remote
noccp
auth
mtu 1280
mru 1280
proxyarp
lcp-echo-failure 4
lcp-echo-interval 30
connect-delay 5000
ms-dns $DNS_SRV1
EOF

  if [ -z "$VPN_DNS_SRV1" ] || [ -n "$VPN_DNS_SRV2" ]; then
cat >> /etc/ppp/options.xl2tpd <<EOF
ms-dns $DNS_SRV2
EOF
  fi

  # Create VPN credentials
  conf_bk "/etc/ppp/chap-secrets"
cat > /etc/ppp/chap-secrets <<EOF
"$VPN_USER" l2tpd "$VPN_PASSWORD" *
EOF

  conf_bk "/etc/ipsec.d/passwd"
  VPN_PASSWORD_ENC=$(openssl passwd -1 "$VPN_PASSWORD")
cat > /etc/ipsec.d/passwd <<EOF
$VPN_USER:$VPN_PASSWORD_ENC:xauth-psk
EOF
}

create_f2b_config() {
  F2B_FILE=/etc/fail2ban/jail.local
  if [ ! -f "$F2B_FILE" ]; then
    bigecho "Creating basic Fail2Ban rules..."
cat > "$F2B_FILE" <<'EOF'
[ssh-iptables]
enabled = true
filter = sshd
logpath = /var/log/secure
EOF

    if [ "$use_nft" = "1" ]; then
cat >> "$F2B_FILE" <<'EOF'
port = ssh
banaction = nftables-multiport[blocktype=drop]
EOF
    else
cat >> "$F2B_FILE" <<'EOF'
action = iptables[name=SSH, port=ssh, protocol=tcp]
EOF
    fi
  fi
}

update_sysctl() {
  bigecho "Updating sysctl settings..."
  if ! grep -qs "hwdsl2 VPN script" /etc/sysctl.conf; then
    conf_bk "/etc/sysctl.conf"
cat >> /etc/sysctl.conf <<EOF

# Added by hwdsl2 VPN script
kernel.msgmnb = 65536
kernel.msgmax = 65536

net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.$NET_IFACE.send_redirects = 0
net.ipv4.conf.$NET_IFACE.rp_filter = 0

net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
EOF
  fi
}

update_iptables() {
  bigecho "Updating IPTables rules..."
  IPT_FILE=/etc/sysconfig/iptables
  [ "$use_nft" = "1" ] && IPT_FILE=/etc/sysconfig/nftables.conf
  ipt_flag=0
  if ! grep -qs "hwdsl2 VPN script" "$IPT_FILE"; then
    ipt_flag=1
  fi

  ipi='iptables -I INPUT'
  ipf='iptables -I FORWARD'
  ipp='iptables -t nat -I POSTROUTING'
  res='RELATED,ESTABLISHED'
  nff='nft insert rule inet firewalld'
  nfn='nft insert rule inet nftables_svc'
  if [ "$ipt_flag" = "1" ]; then
    service fail2ban stop >/dev/null 2>&1
    if [ "$use_nft" = "1" ]; then
      nft list ruleset > "$IPT_FILE.old-$SYS_DT"
      chmod 600 "$IPT_FILE.old-$SYS_DT"
    else
      iptables-save > "$IPT_FILE.old-$SYS_DT"
    fi
    $ipi 1 -p udp --dport 1701 -m policy --dir in --pol none -j DROP
    $ipi 2 -m conntrack --ctstate INVALID -j DROP
    $ipi 3 -m conntrack --ctstate "$res" -j ACCEPT
    $ipi 4 -p udp -m multiport --dports 500,4500 -j ACCEPT
    $ipi 5 -p udp --dport 1701 -m policy --dir in --pol ipsec -j ACCEPT
    $ipi 6 -p udp --dport 1701 -j DROP
    $ipf 1 -m conntrack --ctstate INVALID -j DROP
    $ipf 2 -i "$NET_IFACE" -o ppp+ -m conntrack --ctstate "$res" -j ACCEPT
    $ipf 3 -i ppp+ -o "$NET_IFACE" -j ACCEPT
    $ipf 4 -i ppp+ -o ppp+ -j ACCEPT
    $ipf 5 -i "$NET_IFACE" -d "$XAUTH_NET" -m conntrack --ctstate "$res" -j ACCEPT
    $ipf 6 -s "$XAUTH_NET" -o "$NET_IFACE" -j ACCEPT
    $ipf 7 -s "$XAUTH_NET" -o ppp+ -j ACCEPT
    iptables -A FORWARD -j DROP
    $ipp -s "$XAUTH_NET" -o "$NET_IFACE" -m policy --dir out --pol none -j MASQUERADE
    $ipp -s "$L2TP_NET" -o "$NET_IFACE" -j MASQUERADE
    echo "# Modified by hwdsl2 VPN script" > "$IPT_FILE"
    if [ "$use_nft" = "1" ]; then
      for vport in 500 4500 1701; do
        $nff filter_INPUT udp dport "$vport" accept 2>/dev/null
        $nfn allow udp dport "$vport" accept 2>/dev/null
      done
      for vnet in "$L2TP_NET" "$XAUTH_NET"; do
        for vdir in saddr daddr; do
          $nff filter_FORWARD ip "$vdir" "$vnet" accept 2>/dev/null
          $nfn FORWARD ip "$vdir" "$vnet" accept 2>/dev/null
        done
      done
      echo "flush ruleset" >> "$IPT_FILE"
      nft list ruleset >> "$IPT_FILE"
    else
      iptables-save >> "$IPT_FILE"
    fi
  fi
}

enable_on_boot() {
  bigecho "Enabling services on boot..."
  systemctl --now mask firewalld 2>/dev/null
  if [ "$use_nft" = "1" ]; then
    systemctl enable nftables fail2ban 2>/dev/null
  else
    systemctl enable iptables fail2ban 2>/dev/null
  fi

  if ! grep -qs "hwdsl2 VPN script" /etc/rc.local; then
    if [ -f /etc/rc.local ]; then
      conf_bk "/etc/rc.local"
    else
      echo '#!/bin/sh' > /etc/rc.local
    fi
cat >> /etc/rc.local <<'EOF'

# Added by hwdsl2 VPN script
(sleep 15
service ipsec restart
service xl2tpd restart
echo 1 > /proc/sys/net/ipv4/ip_forward)&
EOF
  fi
}

start_services() {
  bigecho "Starting services..."
  sysctl -e -q -p

  chmod +x /etc/rc.local
  chmod 600 /etc/ipsec.secrets* /etc/ppp/chap-secrets* /etc/ipsec.d/passwd*

  restorecon /etc/ipsec.d/*db 2>/dev/null
  restorecon /usr/local/sbin -Rv 2>/dev/null
  restorecon /usr/local/libexec/ipsec -Rv 2>/dev/null

  if [ "$use_nft" = "1" ]; then
    nft -f "$IPT_FILE"
  else
    iptables-restore < "$IPT_FILE"
  fi

  # Fix xl2tpd if l2tp_ppp is unavailable
  if ! modprobe -q l2tp_ppp; then
    sed -i '/^ExecStartPre=\//s/=/=-/' /usr/lib/systemd/system/xl2tpd.service
    systemctl daemon-reload
  fi

  mkdir -p /run/pluto
  service fail2ban restart 2>/dev/null
  service ipsec restart 2>/dev/null
  service xl2tpd restart 2>/dev/null
}

show_vpn_info() {
cat <<EOF

================================================

IPsec VPN server is now ready for use!

Connect to your new VPN with these details:

Server IP: $public_ip
IPsec PSK: $VPN_IPSEC_PSK
Username: $VPN_USER
Password: $VPN_PASSWORD

Write these down. You'll need them to connect!

Important notes:   https://git.io/vpnnotes
Setup VPN clients: https://git.io/vpnclients
IKEv2 guide:       https://git.io/ikev2

================================================

EOF
}

check_swan_ver() {
  swan_ver_url="https://dl.ls20.com/v1/$os_type/$os_ver/swanver?arch=$os_arch&ver=$SWAN_VER"
  [ "$1" != "0" ] && swan_ver_url="$swan_ver_url&e=$2"
  swan_ver_latest=$(wget -t 3 -T 15 -qO- "$swan_ver_url")
  if printf '%s' "$swan_ver_latest" | grep -Eq '^([3-9]|[1-9][0-9]{1,2})(\.([0-9]|[1-9][0-9]{1,2})){1,2}$' \
    && [ "$1" = "0" ] && [ -n "$SWAN_VER" ] && [ "$SWAN_VER" != "$swan_ver_latest" ] \
    && printf '%s\n%s' "$SWAN_VER" "$swan_ver_latest" | sort -C -V; then
cat <<EOF
Note: A newer version of Libreswan ($swan_ver_latest) is available.
      To update, run:
      wget https://git.io/vpnupgrade -O vpnup.sh && sudo sh vpnup.sh

EOF
  fi
}

finish() {
  check_swan_ver "$1" "$2"
  exit "$1"
}

vpnsetup() {
  check_root
  check_vz
  check_os
  check_iface
  check_creds
  check_dns
  start_setup
  install_setup_pkgs
  detect_ip
  add_epel_repo
  install_vpn_pkgs_1
  install_vpn_pkgs_2
  install_vpn_pkgs_3
  install_fail2ban
  get_ikev2_script
  get_libreswan
  install_libreswan
  create_vpn_config
  create_f2b_config
  update_sysctl
  update_iptables
  enable_on_boot
  start_services
  show_vpn_info
}

## Defer setup until we have the complete script
vpnsetup "$@"

exit 0
