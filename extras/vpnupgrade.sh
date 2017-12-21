#!/bin/sh
#
# Script to upgrade Libreswan on Ubuntu and Debian
#
# Copyright (C) 2016-2017 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

# Check https://libreswan.org for the latest version
SWAN_VER=3.22

### DO NOT edit below this line ###

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }

vpnupgrade() {

os_type="$(lsb_release -si 2>/dev/null)"
if [ -z "$os_type" ]; then
  [ -f /etc/os-release  ] && os_type="$(. /etc/os-release  && echo "$ID")"
  [ -f /etc/lsb-release ] && os_type="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if ! printf '%s' "$os_type" | head -n 1 | grep -qiF -e ubuntu -e debian -e raspbian; then
  exiterr "This script only supports Ubuntu and Debian."
fi

if [ "$(sed 's/\..*//' /etc/debian_version)" = "7" ]; then
  exiterr "Debian 7 is not supported."
fi

if [ -f /proc/user_beancounters ]; then
  exiterr "OpenVZ VPS is not supported."
fi

if [ "$(id -u)" != 0 ]; then
  exiterr "Script must be run as root. Try 'sudo sh $0'"
fi

if [ -z "$SWAN_VER" ]; then
  exiterr "Libreswan version 'SWAN_VER' not specified."
fi

if ! /usr/local/sbin/ipsec --version 2>/dev/null | grep -q "Libreswan"; then
  exiterr "This script requires Libreswan already installed."
fi

if [ "$SWAN_VER" = "3.22" ]; then
  if grep -qs raspbian /etc/os-release; then
    echo "Note: For Raspberry Pi systems, this script will install Libreswan"
    echo "version 3.21 instead of 3.22, to avoid some recent bugs."
    echo
    printf "Do you wish to continue? [y/N] "
    read -r response
    case $response in
      [yY][eE][sS]|[yY])
        echo
        SWAN_VER=3.21
        ;;
      *)
        echo "Aborting."
        exit 1
        ;;
    esac
  fi
fi

if /usr/local/sbin/ipsec --version 2>/dev/null | grep -qF "$SWAN_VER"; then
  echo "You already have Libreswan version $SWAN_VER installed! "
  echo "If you continue, the same version will be re-installed."
  echo
  printf "Do you wish to continue anyway? [y/N] "
  read -r response
  case $response in
    [yY][eE][sS]|[yY])
      echo
      ;;
    *)
      echo "Aborting."
      exit 1
      ;;
  esac
fi

clear

cat <<EOF
Welcome! This script will build and install Libreswan $SWAN_VER on your server.
Additional packages required for Libreswan compilation will also be installed.

This is intended for use on servers running an older version of Libreswan.

EOF

cat <<'EOF'
IMPORTANT NOTES:

Libreswan versions 3.19 and newer require some configuration changes.
This script will make the following changes to your /etc/ipsec.conf:

Replace this line:
  auth=esp
with the following:
  phase2=esp

Replace this line:
  forceencaps=yes
with the following:
  encapsulation=yes

Consolidate VPN ciphers for "ike=" and "phase2alg=".
Re-add "MODP1024" to the list of allowed "ike=" ciphers,
which was removed from the defaults in Libreswan 3.19.

Your other VPN configuration files will not be modified.

EOF

printf "Do you wish to continue? [y/N] "
read -r response
case $response in
  [yY][eE][sS]|[yY])
    echo
    echo "Please be patient. Setup is continuing..."
    echo
    ;;
  *)
    echo "Aborting."
    exit 1
    ;;
esac

# Create and change to working dir
mkdir -p /opt/src
cd /opt/src || exiterr "Cannot enter /opt/src."

# Update package index and install Wget
export DEBIAN_FRONTEND=noninteractive
apt-get -yq update || exiterr "'apt-get update' failed."
apt-get -yq install wget || exiterr2

# Install necessary packages
apt-get -yq install libnss3-dev libnspr4-dev pkg-config \
  libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux1-dev \
  libcurl4-nss-dev flex bison gcc make libnss3-tools \
  libevent-dev || exiterr2

# Compile and install Libreswan
swan_file="libreswan-$SWAN_VER.tar.gz"
swan_url1="https://github.com/libreswan/libreswan/archive/v$SWAN_VER.tar.gz"
swan_url2="https://download.libreswan.org/$swan_file"
if ! { wget -t 3 -T 30 -nv -O "$swan_file" "$swan_url1" || wget -t 3 -T 30 -nv -O "$swan_file" "$swan_url2"; }; then
  exiterr "Cannot download Libreswan source."
fi
/bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
tar xzf "$swan_file" && /bin/rm -f "$swan_file"
cd "libreswan-$SWAN_VER" || exiterr "Cannot enter Libreswan source dir."
[ "$SWAN_VER" = "3.22" ] && sed -i '/^#define LSWBUF_CANARY/s/-2$/((char) -2)/' include/lswlog.h
cat > Makefile.inc.local <<'EOF'
WERROR_CFLAGS =
USE_DNSSEC = false
EOF
if [ "$(packaging/utils/lswan_detect.sh init)" = "systemd" ]; then
  apt-get -yq install libsystemd-dev || exiterr2
fi
NPROCS="$(grep -c ^processor /proc/cpuinfo)"
[ -z "$NPROCS" ] && NPROCS=1
make "-j$((NPROCS+1))" -s base && make -s install-base

# Verify the install and clean up
cd /opt/src || exiterr "Cannot enter /opt/src."
/bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
if ! /usr/local/sbin/ipsec --version 2>/dev/null | grep -qF "$SWAN_VER"; then
  exiterr "Libreswan $SWAN_VER failed to build."
fi

# Update ipsec.conf for Libreswan 3.19 and newer
IKE_NEW="  ike=3des-sha1,3des-sha2,aes-sha1,aes-sha1;modp1024,aes-sha2,aes-sha2;modp1024,aes256-sha2_512"
PHASE2_NEW="  phase2alg=3des-sha1,3des-sha2,aes-sha1,aes-sha2,aes256-sha2_512"
if grep -qs raspbian /etc/os-release; then
  PHASE2_NEW="  phase2alg=3des-sha1,3des-sha2,aes-sha1,aes-sha2"
fi
sed -i".old-$(date +%F-%T)" \
    -e "s/^[[:space:]]\+auth=esp\$/  phase2=esp/" \
    -e "s/^[[:space:]]\+forceencaps=yes\$/  encapsulation=yes/" \
    -e "s/^[[:space:]]\+ike=.\+\$/$IKE_NEW/" \
    -e "s/^[[:space:]]\+phase2alg=.\+\$/$PHASE2_NEW/" /etc/ipsec.conf

# Restart IPsec service
service ipsec restart

echo
echo "Libreswan $SWAN_VER was installed successfully! "
echo

}

## Defer setup until we have the complete script
vpnupgrade "$@"

exit 0
