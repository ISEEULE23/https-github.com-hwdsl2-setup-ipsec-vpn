﻿# IPsec VPN Server Auto Setup Scripts

[![Build Status](https://static.ls20.com/travis-ci/setup-ipsec-vpn.svg)](https://travis-ci.org/hwdsl2/setup-ipsec-vpn) 
[![Author](https://img.shields.io/badge/author-Lin%20Song-blue.svg?maxAge=2592000)](https://www.linkedin.com/in/linsongui) 
[![GitHub stars](https://img.shields.io/github/stars/hwdsl2/setup-ipsec-vpn.svg?maxAge=3600)](https://github.com/hwdsl2/setup-ipsec-vpn/stargazers) 
[![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?maxAge=3600)](https://github.com/hwdsl2/docker-ipsec-vpn-server)

Set up your own IPsec VPN server in just a few minutes, with both IPsec/L2TP and Cisco IPsec on Ubuntu, Debian and CentOS. All you need to do is provide your own VPN credentials, and let the scripts handle the rest.

An IPsec VPN encrypts your network traffic, so that nobody between you and the VPN server can eavesdrop on your data as it travels via the Internet. This is especially useful when using unsecured networks, e.g. at coffee shops, airports or hotel rooms.

We will use <a href="https://libreswan.org/" target="_blank">Libreswan</a> as the IPsec server, and <a href="https://github.com/xelerance/xl2tpd" target="_blank">xl2tpd</a> as the L2TP provider.

<a href="https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/" target="_blank">**&raquo; Related tutorial: IPsec VPN Server Auto Setup with Libreswan**</a>

*Read this in other languages: [English](README.md), [简体中文](README-zh.md).*

#### Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Ubuntu & Debian](#ubuntu--debian)
  - [CentOS & RHEL](#centos--rhel)
- [Next Steps](#next-steps)
- [Important Notes](#important-notes)
- [Upgrade Libreswan](#upgrade-libreswan)
- [Bugs & Questions](#bugs--questions)
- [Uninstallation](#uninstallation)
- [See Also](#see-also)
- [Author](#author)
- [License](#license)

## Features

- **New:** The faster `IPsec/XAuth ("Cisco IPsec")` mode is supported
- **New:** A pre-built [Docker image](#see-also) of the VPN server is now available
- Fully automated IPsec VPN server setup, no user input needed
- Encapsulates all VPN traffic in UDP - does not need ESP protocol
- Can be directly used as "user-data" for a new Amazon EC2 instance
- Automatically determines public IP and private IP of server
- Includes basic IPTables rules and `sysctl.conf` settings
- Tested with Ubuntu 16.04/14.04/12.04, Debian 8 and CentOS 6 & 7

## Requirements

A newly created <a href="https://aws.amazon.com/ec2/" target="_blank">Amazon EC2</a> instance, using one of these AMIs:
- <a href="https://cloud-images.ubuntu.com/locator/" target="_blank">Ubuntu 16.04 (Xenial), 14.04 (Trusty) or 12.04 (Precise)</a>
- <a href="https://wiki.debian.org/Cloud/AmazonEC2Image" target="_blank">Debian 8 (Jessie) EC2 Images</a>
- <a href="https://aws.amazon.com/marketplace/pp/B00O7WM7QW" target="_blank">CentOS 7 (x86_64) with Updates</a>
- <a href="https://aws.amazon.com/marketplace/pp/B00NQAYLWO" target="_blank">CentOS 6 (x86_64) with Updates</a>

Please refer to <a href="https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#vpnsetup" target="_blank">detailed instructions</a> and <a href="https://aws.amazon.com/ec2/pricing/" target="_blank">EC2 pricing</a>.

**-OR-**

A dedicated server or Virtual Private Server (VPS), freshly installed with one of the above OS. In addition, Debian 7 (Wheezy) can also be used with <a href="extras/vpnsetup-debian-7-workaround.sh" target="_blank">this workaround</a>. OpenVZ VPS is NOT supported, users could instead try <a href="https://github.com/Nyr/openvpn-install" target="_blank">OpenVPN</a>.

This also includes Linux VMs in public clouds such as Google Compute Engine, Amazon EC2, Microsoft Azure, IBM SoftLayer, VMware vCloud Air, Rackspace, DigitalOcean, Vultr and Linode.

<a href="azure/README.md" target="_blank"><img src="docs/images/azure-deploy-button.png" alt="Deploy to Azure" /></a> <a href="http://dovpn.carlfriess.com/" target="_blank"><img src="docs/images/do-install-button.png" alt="Install on DigitalOcean" /></a> <a href="https://www.linode.com/stackscripts/view/37239" target="_blank"><img src="docs/images/linode-deploy-button.png" alt="Deploy to Linode" /></a>

<a href="https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#gettingavps" target="_blank">**&raquo; I want to run my own VPN but don't have a server for that**</a>

:warning: **DO NOT** run these scripts on your PC or Mac! They should only be used on a server!

## Installation

### Ubuntu & Debian

First, update your system with `apt-get update && apt-get dist-upgrade` and reboot. This is optional, but recommended.

To install the VPN, please choose one of the following options:

**Option 1:** Have the script generate random VPN credentials for you (will be displayed when finished):

```bash
wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh
```

**Option 2:** Edit the script and provide your own VPN credentials:

```bash
wget https://git.io/vpnsetup -O vpnsetup.sh
nano -w vpnsetup.sh
[Replace with your own values: YOUR_IPSEC_PSK, YOUR_USERNAME and YOUR_PASSWORD]
sudo sh vpnsetup.sh
```

**Option 3:** Define your VPN credentials as environment variables:

```bash
# All values MUST be placed inside 'single quotes'
# DO NOT use these characters within values:  \ " '
wget https://git.io/vpnsetup -O vpnsetup.sh && sudo \
VPN_IPSEC_PSK='your_ipsec_pre_shared_key' \
VPN_USER='your_vpn_username' \
VPN_PASSWORD='your_vpn_password' sh vpnsetup.sh
```

DigitalOcean users may refer to this <a href="https://usefulpcguide.com/17318/create-your-own-vpn/" target="_blank">step-by-step guide</a> by Tony Tran.

**Note:** If unable to download via `wget`, you may also open <a href="vpnsetup.sh" target="_blank">vpnsetup.sh</a> (or <a href="vpnsetup_centos.sh" target="_blank">vpnsetup_centos.sh</a>) and click the **`Raw`** button. Press `Ctrl-A` to select all, `Ctrl-C` to copy, then paste into your favorite editor.

### CentOS & RHEL

First, update your system with `yum update` and reboot. This is optional, but recommended.

Follow the same steps as above, but replace `https://git.io/vpnsetup` with `https://git.io/vpnsetup-centos`.

## Next Steps

Get your computer or device to use the VPN. Please refer to:

<a href="docs/clients.md" target="_blank">Configure IPsec/L2TP VPN Clients</a>   
<a href="docs/clients-xauth.md" target="_blank">Configure IPsec/XAuth ("Cisco IPsec") VPN Clients</a>

<a href="docs/ikev2-howto.md" target="_blank">How To: IKEv2 VPN for Windows 7 and newer</a>

Enjoy your very own VPN! :sparkles::tada::rocket::sparkles:

## Important Notes

**Windows users**: If you get an error when trying to connect, see <a href="docs/clients.md#troubleshooting" target="_blank">Troubleshooting</a>.

**Android 6 (Marshmallow) users**: Please see notes in <a href="docs/clients.md#android" target="_blank">Configure IPsec/L2TP VPN Clients</a>.

If you wish to add, edit or remove VPN user accounts, refer to <a href="docs/manage-users.md" target="_blank">Manage VPN Users</a>.

Clients are set to use <a href="https://developers.google.com/speed/public-dns/" target="_blank">Google Public DNS</a> when the VPN is active. If another DNS provider is preferred, replace `8.8.8.8` and `8.8.4.4` in both `/etc/ppp/options.xl2tpd` and `/etc/ipsec.conf`. Then reboot your server.

For servers with an external firewall (e.g. <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html" target="_blank">EC2</a>/<a href="https://cloud.google.com/compute/docs/networking#firewalls" target="_blank">GCE</a>), open UDP ports 500 & 4500, and TCP port 22 (for SSH).

To open additional ports on the server, edit `/etc/iptables.rules` and/or `/etc/iptables/rules.v4` (Ubuntu/Debian), or `/etc/sysconfig/iptables` (CentOS). Then reboot your server.

When connecting via `IPsec/L2TP`, the VPN server has IP `192.168.42.1` within the VPN subnet `192.168.42.0/24`.

The scripts will backup existing config files before making changes, with `.old-date-time` suffix.

## Upgrade Libreswan

The additional scripts <a href="extras/vpnupgrade.sh" target="_blank">vpnupgrade.sh</a> and <a href="extras/vpnupgrade_centos.sh" target="_blank">vpnupgrade_centos.sh</a> can be used to upgrade Libreswan (<a href="https://libreswan.org" target="_blank">website</a> | <a href="https://lists.libreswan.org/mailman/listinfo/swan-announce" target="_blank">mailing list</a>). Edit the `swan_ver` variable as necessary. Check installed version: `ipsec --version`

## Bugs & Questions

- Got a question? Please first search other people's comments <a href="https://gist.github.com/hwdsl2/9030462#comments" target="_blank">in this Gist</a> and <a href="https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#disqus_thread" target="_blank">on my blog</a>.
- Ask VPN related questions on these mailing lists: <a href="https://lists.libreswan.org/mailman/listinfo/swan" target="_blank">[1]</a> <a href="https://lists.strongswan.org/mailman/listinfo/users" target="_blank">[2]</a>, or read related articles: <a href="https://libreswan.org/wiki/Main_Page" target="_blank">[1]</a> <a href="https://wiki.gentoo.org/wiki/IPsec_L2TP_VPN_server" target="_blank">[2]</a> <a href="https://wiki.archlinux.org/index.php/L2TP/IPsec_VPN_client_setup" target="_blank">[3]</a> <a href="https://wiki.strongswan.org/projects/strongswan/wiki/UserDocumentation" target="_blank">[4]</a>.
- If you found a reproducible bug, open a <a href="https://github.com/hwdsl2/setup-ipsec-vpn/issues?q=is%3Aissue" target="_blank">GitHub Issue</a> to submit a bug report.

## Uninstallation

Please refer to <a href="docs/uninstall.md" target="_blank">Uninstall the VPN</a>.

## See Also

- <a href="https://github.com/hwdsl2/docker-ipsec-vpn-server" target="_blank">IPsec VPN Server on Docker</a>
- <a href="https://github.com/gaomd/docker-ikev2-vpn-server" target="_blank">IKEv2 VPN Server on Docker</a>
- <a href="https://github.com/jlund/streisand" target="_blank">Streisand</a>
- <a href="https://github.com/SoftEtherVPN/SoftEtherVPN" target="_blank">SoftEther VPN</a>
- <a href="https://github.com/breakwa11/shadowsocks-rss" target="_blank">ShadowsocksR</a>
- <a href="https://github.com/Nyr/openvpn-install" target="_blank">OpenVPN Install</a>
- <a href="https://github.com/philpl/setup-strong-strongswan" target="_blank">Setup strongSwan</a>

## Author

**Lin Song** (linsongui@gmail.com)   
- Final year U.S. PhD candidate, majoring in Electrical and Computer Engineering (ECE)
- Actively seeking opportunities in areas such as Software or Systems Engineering
- Contact me on LinkedIn: <a href="https://www.linkedin.com/in/linsongui" target="_blank">https://www.linkedin.com/in/linsongui</a>

Thanks to <a href="https://github.com/hwdsl2/setup-ipsec-vpn/graphs/contributors" target="_blank">all contributors</a> to this project!

## License

Copyright (C) 2014-2016&nbsp;Lin Song&nbsp;&nbsp;&nbsp;<a href="https://www.linkedin.com/in/linsongui" target="_blank"><img src="https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png" width="160" height="25" border="0" alt="View my profile on LinkedIn"></a>    
Based on <a href="https://github.com/sarfata/voodooprivacy" target="_blank">the work of Thomas Sarlandie</a> (Copyright 2012)

This work is licensed under the <a href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike 3.0 Unported License</a>  
Attribution required: please include my name in any derivative and let me know how you have improved it!
