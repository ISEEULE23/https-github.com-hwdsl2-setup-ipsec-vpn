# IPsec VPN Server Auto Setup Scripts

[![Build Status](https://img.shields.io/github/workflow/status/hwdsl2/setup-ipsec-vpn/vpn%20test.svg?cacheSeconds=3600)](https://github.com/hwdsl2/setup-ipsec-vpn/actions/workflows/main.yml) [![GitHub Stars](https://img.shields.io/github/stars/hwdsl2/setup-ipsec-vpn.svg?cacheSeconds=86400&logo=github)](https://github.com/hwdsl2/setup-ipsec-vpn/stargazers) [![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg?cacheSeconds=86400&logo=docker)](https://github.com/hwdsl2/docker-ipsec-vpn-server) [![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?cacheSeconds=86400&logo=docker)](https://github.com/hwdsl2/docker-ipsec-vpn-server)

Set up your own IPsec VPN server in just a few minutes, with IPsec/L2TP, Cisco IPsec and IKEv2. All you need to do is provide your own VPN credentials, and let the scripts handle the rest.

An IPsec VPN encrypts your network traffic, so that nobody between you and the VPN server can eavesdrop on your data as it travels via the Internet. This is especially useful when using unsecured networks, e.g. at coffee shops, airports or hotel rooms.

We will use [Libreswan](https://libreswan.org/) as the IPsec server, and [xl2tpd](https://github.com/xelerance/xl2tpd) as the L2TP provider.

*Read this in other languages: [English](README.md), [简体中文](README-zh.md).*

#### Table of Contents

- [Quick start](#quick-start)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Next steps](#next-steps)
- [Important notes](#important-notes)
- [Upgrade Libreswan](#upgrade-libreswan)
- [Manage VPN users](#manage-vpn-users)
- [Advanced usage](#advanced-usage)
- [Uninstallation](#uninstallation)
- [Feedback & Questions](#feedback--questions)
- [License](#license)

## Quick start

First, prepare your Linux server\* with a fresh install of one of the following OS:   
Ubuntu, Debian, CentOS/RHEL, Rocky Linux, AlmaLinux, Amazon Linux 2 or Alpine Linux

Use this one-liner to set up an IPsec VPN server:

```bash
wget https://git.io/vpnsetup -qO vpn.sh && sudo sh vpn.sh
```

Your VPN login details will be randomly generated, and displayed on the screen when finished.

<details>
<summary>
Alternative one-liner using curl.
</summary>

```bash
curl -fsSL https://git.io/vpnsetup -o vpn.sh && sudo sh vpn.sh
```
</details>

<details>
<summary>
See the VPN script in action (terminal recording).
</summary>

**Note:** This recording is for demo purposes only. VPN credentials in this recording are **NOT** valid.
<p align="center"><img src="docs/images/script-demo.svg"></p>
</details>

A pre-built [Docker image](https://github.com/hwdsl2/docker-ipsec-vpn-server) is also available. For other installation options and client setup, read the sections below.

\* A dedicated server or virtual private server (VPS). OpenVZ VPS is not supported.

## Features

- **New:** The faster IPsec/XAuth ("Cisco IPsec") and IKEv2 modes are supported
- **New:** A pre-built [Docker image](https://github.com/hwdsl2/docker-ipsec-vpn-server) of the VPN server is now available
- Fully automated IPsec VPN server setup, no user input needed
- Encapsulates all VPN traffic in UDP - does not need ESP protocol
- Can be directly used as "user-data" for a new Amazon EC2 instance
- Includes `sysctl.conf` optimizations for improved performance

## Requirements

A dedicated server or virtual private server (VPS), freshly installed with one of the following OS:

- Ubuntu 20.04 or 18.04
- Debian 11[\*](#debian-10-note), 10[\*](#debian-10-note) or 9
- CentOS 7, Rocky Linux 8 or AlmaLinux 8[\*\*](#centos-8-note)
- Red Hat Enterprise Linux (RHEL) 8 or 7
- Amazon Linux 2
- Alpine Linux 3.15 or 3.14

This also includes Linux VMs in public clouds, such as [DigitalOcean](https://blog.ls20.com/digitalocean), [Vultr](https://blog.ls20.com/vultr), [Linode](https://blog.ls20.com/linode), [Microsoft Azure](https://azure.microsoft.com) and [OVH](https://www.ovhcloud.com/en/vps/). [Amazon EC2](https://aws.amazon.com/ec2/) users can deploy rapidly using [CloudFormation](aws/README.md) or [user data](https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#vpnsetup).

[![Deploy to DigitalOcean](docs/images/do-install-button.png)](http://dovpn.carlfriess.com) [![Deploy to Linode](docs/images/linode-deploy-button.png)](https://cloud.linode.com/stackscripts/37239) [![Deploy to AWS](docs/images/aws-deploy-button.png)](aws/README.md) [![Deploy to Azure](docs/images/azure-deploy-button.png)](azure/README.md)

[**&raquo; I want to run my own VPN but don't have a server for that**](https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#gettingavps)

A pre-built [Docker image](https://github.com/hwdsl2/docker-ipsec-vpn-server) is also available. Advanced users can install on a [Raspberry Pi](https://www.raspberrypi.org). [[1]](https://elasticbyte.net/posts/setting-up-a-native-cisco-ipsec-vpn-server-using-a-raspberry-pi/) [[2]](https://www.stewright.me/2018/07/create-a-raspberry-pi-vpn-server-using-l2tpipsec/)

<a name="debian-10-note"></a>
\* Debian 11/10 users should [use the standard Linux kernel](docs/clients.md#debian-10-kernel).   
<a name="centos-8-note"></a>
\*\* CentOS Linux 8 [is no longer supported](https://www.centos.org/centos-linux-eol/). You may instead use e.g. Rocky Linux or AlmaLinux.

:warning: **DO NOT** run these scripts on your PC or Mac! They should only be used on a server!

## Installation

First, update your server with `sudo apt-get update && sudo apt-get dist-upgrade` (Ubuntu/Debian) or `sudo yum update` and reboot. This is optional, but recommended.

To install the VPN, please choose one of the following options:

**Option 1:** Have the script generate random VPN credentials for you (will be displayed when finished).

```bash
wget https://git.io/vpnsetup -qO vpn.sh && sudo sh vpn.sh
```

**Option 2:** Edit the script and provide your own VPN credentials.

```bash
wget https://git.io/vpnsetup -nv -O vpn.sh
nano -w vpn.sh
[Replace with your own values: YOUR_IPSEC_PSK, YOUR_USERNAME and YOUR_PASSWORD]
sudo sh vpn.sh
```

**Note:** A secure IPsec PSK should consist of at least 20 random characters.

**Option 3:** Define your VPN credentials as environment variables.

```bash
# All values MUST be placed inside 'single quotes'
# DO NOT use these special characters within values: \ " '
wget https://git.io/vpnsetup -nv -O vpn.sh
sudo VPN_IPSEC_PSK='your_ipsec_pre_shared_key' \
VPN_USER='your_vpn_username' \
VPN_PASSWORD='your_vpn_password' \
sh vpn.sh
```

<details>
<summary>
Advanced users can optionally customize IKEv2 options.
</summary>

Advanced users can optionally specify a DNS name for the IKEv2 server address. The DNS name must be a fully qualified domain name (FQDN). Example:

```bash
sudo VPN_DNS_NAME='vpn.example.com' sh vpn.sh
```

Similarly, you may specify a name for the first IKEv2 client. The default is `vpnclient` if not specified.

```bash
sudo VPN_CLIENT_NAME='your_client_name' sh vpn.sh
```

By default, clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN is active. You may specify custom DNS server(s) for all VPN modes. Example:

```bash
sudo VPN_DNS_SRV1=1.1.1.1 VPN_DNS_SRV2=1.0.0.1 sh vpn.sh
```

By default, no password is required when importing IKEv2 client configuration. You can choose to protect client config files using a random password. Example:

```bash
sudo VPN_PROTECT_CONFIG=yes sh vpn.sh
```
</details>
<details>
<summary>
Click here if you are unable to download using wget.
</summary>

You may also use `curl` to download. For example:

```bash
curl -fsSL https://git.io/vpnsetup -o vpn.sh
sudo sh vpn.sh
```

Alternatively, open [vpnsetup.sh](vpnsetup.sh) and click the `Raw` button on the right. Press `Ctrl/Cmd+A` to select all, `Ctrl/Cmd+C` to copy, then paste into your favorite editor.
</details>

## Next steps

Get your computer or device to use the VPN. Please refer to:

[**Guide: How to Set Up and Use IKEv2 VPN**](docs/ikev2-howto.md)

[**Configure IPsec/L2TP VPN Clients**](docs/clients.md)

[**Configure IPsec/XAuth ("Cisco IPsec") VPN Clients**](docs/clients-xauth.md)

If you get an error when trying to connect, see [Troubleshooting](docs/clients.md#troubleshooting).

Enjoy your very own VPN! :sparkles::tada::rocket::sparkles:

## Important notes

*Read this in other languages: [English](README.md#important-notes), [简体中文](README-zh.md#重要提示).*

**Windows users**: For IPsec/L2TP mode, a [one-time registry change](docs/clients.md#windows-error-809) is required if the VPN server or client is behind NAT (e.g. home router).

The same VPN account can be used by your multiple devices. However, due to an IPsec/L2TP limitation, if you wish to connect multiple devices from behind the same NAT (e.g. home router), you must use [IKEv2](docs/ikev2-howto.md) or [IPsec/XAuth](docs/clients-xauth.md) mode.

To view or update VPN user accounts, see [Manage VPN users](docs/manage-users.md). Helper scripts are included for convenience.

For servers with an external firewall (e.g. [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)), open UDP ports 500 and 4500 for the VPN. Aliyun users, see [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433).

Clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN is active. If another DNS provider is preferred, see [Advanced usage](docs/advanced-usage.md).

Using kernel support could improve IPsec/L2TP performance. It is available on [all supported OS](#requirements). Ubuntu users should install the `linux-modules-extra-$(uname -r)` (or `linux-image-extra`) package and run `service xl2tpd restart`.

The scripts will backup existing config files before making changes, with `.old-date-time` suffix.

## Upgrade Libreswan

Use this one-liner to update [Libreswan](https://libreswan.org) ([changelog](https://github.com/libreswan/libreswan/blob/main/CHANGES) | [announce](https://lists.libreswan.org/mailman/listinfo/swan-announce)) on your VPN server.

```bash
wget https://git.io/vpnupgrade -qO vpnup.sh && sudo sh vpnup.sh
```

The latest supported Libreswan version is `4.6`. Check installed version: `ipsec --version`.

**Note:** `xl2tpd` can be updated using your system's package manager, such as `apt-get` on Ubuntu/Debian.

## Manage VPN users

See [Manage VPN users](docs/manage-users.md).

- [Manage VPN users using helper scripts](docs/manage-users.md#manage-vpn-users-using-helper-scripts)
- [View VPN users](docs/manage-users.md#view-vpn-users)
- [View or update the IPsec PSK](docs/manage-users.md#view-or-update-the-ipsec-psk)
- [Manually manage VPN users](docs/manage-users.md#manually-manage-vpn-users)

## Advanced usage

See [Advanced usage](docs/advanced-usage.md).

- [Use alternative DNS servers](docs/advanced-usage.md#use-alternative-dns-servers)
- [DNS name and server IP changes](docs/advanced-usage.md#dns-name-and-server-ip-changes)
- [IKEv2-only VPN](docs/advanced-usage.md#ikev2-only-vpn)
- [Internal VPN IPs and traffic](docs/advanced-usage.md#internal-vpn-ips-and-traffic)
- [Port forwarding to VPN clients](docs/advanced-usage.md#port-forwarding-to-vpn-clients)
- [Split tunneling](docs/advanced-usage.md#split-tunneling)
- [Access VPN server's subnet](docs/advanced-usage.md#access-vpn-servers-subnet)
- [Modify IPTables rules](docs/advanced-usage.md#modify-iptables-rules)
- [Deploy Google BBR congestion control](docs/advanced-usage.md#deploy-google-bbr-congestion-control)

## Uninstallation

See [Uninstall the VPN](docs/uninstall.md).

- [Uninstall using helper script](docs/uninstall.md#uninstall-using-helper-script)
- [Manually uninstall the VPN](docs/uninstall.md#manually-uninstall-the-vpn)

## Feedback & Questions

- Have an improvement suggestion for documentation or VPN scripts? Open an [Enhancement request](https://github.com/hwdsl2/setup-ipsec-vpn/issues/new/choose). [Pull requests](https://github.com/hwdsl2/setup-ipsec-vpn/pulls) are also welcome.
- If you found a reproducible bug, open a bug report for the [IPsec VPN](https://github.com/libreswan/libreswan/issues?q=is%3Aissue) or for the [VPN scripts](https://github.com/hwdsl2/setup-ipsec-vpn/issues/new/choose).
- Got a question? Please first search [existing issues](https://github.com/hwdsl2/setup-ipsec-vpn/issues?q=is%3Aissue) and comments [in this Gist](https://gist.github.com/hwdsl2/9030462#comments) and [on my blog](https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#disqus_thread).
- Ask VPN related questions on the [Libreswan](https://lists.libreswan.org/mailman/listinfo/swan) or [strongSwan](https://lists.strongswan.org/mailman/listinfo/users) mailing list, or read these wikis: [[1]](https://libreswan.org/wiki/Main_Page) [[2]](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-securing_virtual_private_networks) [[3]](https://wiki.strongswan.org/projects/strongswan/wiki/UserDocumentation) [[4]](https://wiki.gentoo.org/wiki/IPsec_L2TP_VPN_server) [[5]](https://wiki.archlinux.org/index.php/Openswan_L2TP/IPsec_VPN_client_setup).

## License

Copyright (C) 2014-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
Based on [the work of Thomas Sarlandie](https://github.com/sarfata/voodooprivacy) (Copyright 2012)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)  
Attribution required: please include my name in any derivative and let me know how you have improved it!
