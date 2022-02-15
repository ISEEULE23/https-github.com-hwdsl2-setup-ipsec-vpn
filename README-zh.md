# IPsec VPN 服务器一键安装脚本

[![Build Status](https://img.shields.io/github/workflow/status/hwdsl2/setup-ipsec-vpn/vpn%20test.svg?cacheSeconds=3600)](https://github.com/hwdsl2/setup-ipsec-vpn/actions/workflows/main.yml) [![GitHub Stars](https://img.shields.io/github/stars/hwdsl2/setup-ipsec-vpn.svg?cacheSeconds=86400&logo=github)](https://github.com/hwdsl2/setup-ipsec-vpn/stargazers) [![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg?cacheSeconds=86400&logo=docker)](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md) [![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?cacheSeconds=86400&logo=docker)](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)

使用 Linux 脚本一键快速搭建自己的 IPsec VPN 服务器。支持 IPsec/L2TP, Cisco IPsec 和 IKEv2 协议。你只需提供自己的 VPN 登录凭证，然后运行脚本自动完成安装。

IPsec VPN 可以加密你的网络流量，以防止在通过因特网传送时，你和 VPN 服务器之间的任何人对你的数据的未经授权的访问。在使用不安全的网络时，这是特别有用的，例如在咖啡厅，机场或旅馆房间。

我们将使用 [Libreswan](https://libreswan.org/) 作为 IPsec 服务器，以及 [xl2tpd](https://github.com/xelerance/xl2tpd) 作为 L2TP 提供者。

*其他语言版本: [English](README.md), [简体中文](README-zh.md).*

#### 目录

- [快速开始](#快速开始)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [安装说明](#安装说明)
- [下一步](#下一步)
- [重要提示](#重要提示)
- [升级Libreswan](#升级libreswan)
- [管理 VPN 用户](#管理-vpn-用户)
- [高级用法](#高级用法)
- [卸载说明](#卸载说明)
- [问题和反馈](#问题和反馈)
- [授权协议](#授权协议)

## 快速开始

首先，在你的 Linux 服务器\* 上全新安装以下系统之一：   
Ubuntu, Debian, CentOS/RHEL, Rocky Linux, AlmaLinux, Amazon Linux 2 或者 Alpine Linux

使用以下命令快速搭建 IPsec VPN 服务器：

```bash
wget https://git.io/vpnstart -qO vpn.sh && sudo sh vpn.sh
```

你的 VPN 登录凭证将会被自动随机生成，并在安装完成后显示在屏幕上。

<details>
<summary>
或者，你也可以使用 curl 下载。
</summary>

```bash
curl -fsSL https://git.io/vpnstart -o vpn.sh && sudo sh vpn.sh
```
</details>

<details>
<summary>
查看 VPN 脚本的示例输出（终端记录）。
</summary>

**注：** 此终端记录仅用于演示目的。该记录中的 VPN 凭据 **无效**。
<p align="center"><img src="docs/images/script-demo.svg"></p>
</details>

另外，你也可以使用预构建的 [Docker 镜像](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)。如需了解其它安装选项以及客户端配置，请继续阅读以下部分。

\* 一个专用服务器或者虚拟专用服务器 (VPS)。OpenVZ VPS 不受支持。

## 功能特性

- **新:** 增加支持更高效的 IPsec/XAuth ("Cisco IPsec") 和 IKEv2 模式
- **新:** 现在可以下载 VPN 服务器的预构建 [Docker 镜像](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)
- 全自动的 IPsec VPN 服务器配置，无需用户输入
- 封装所有的 VPN 流量在 UDP 协议，不需要 ESP 协议支持
- 可直接作为 Amazon EC2 实例创建时的用户数据使用
- 包含 `sysctl.conf` 优化设置，以达到更佳的传输性能

## 系统要求

一个专用服务器或者虚拟专用服务器 (VPS)，全新安装以下操作系统之一：

- Ubuntu 20.04 或者 18.04
- Debian 11[\*](#debian-10-note), 10[\*](#debian-10-note) 或者 9
- CentOS 7, Rocky Linux 8 或者 AlmaLinux 8[\*\*](#centos-8-note)
- Red Hat Enterprise Linux (RHEL) 8 或者 7
- Amazon Linux 2
- Alpine Linux 3.15 或者 3.14

这也包括各种公共云服务中的 Linux 虚拟机，比如 [DigitalOcean](https://blog.ls20.com/digitalocean), [Vultr](https://blog.ls20.com/vultr), [Linode](https://blog.ls20.com/linode), [Microsoft Azure](https://azure.microsoft.com) 和 [OVH](https://www.ovhcloud.com/en/vps/)。[Amazon EC2](https://aws.amazon.com/ec2/) 用户可以使用 [CloudFormation](aws/README-zh.md) 或者 [用户数据](https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#vpnsetup) 快速部署。

[![Deploy to AWS](docs/images/aws-deploy-button.png)](aws/README-zh.md) &nbsp;[![Deploy to Azure](docs/images/azure-deploy-button.png)](azure/README-zh.md) &nbsp;[![Deploy to Linode](docs/images/linode-deploy-button.png)](https://cloud.linode.com/stackscripts/37239)

[**&raquo; 我想建立并使用自己的 VPN ，但是没有可用的服务器**](https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#gettingavps)

另外，你也可以使用预构建的 [Docker 镜像](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)。高级用户可以在 [Raspberry Pi](https://www.raspberrypi.org) 上安装。[[1]](https://elasticbyte.net/posts/setting-up-a-native-cisco-ipsec-vpn-server-using-a-raspberry-pi/) [[2]](https://www.stewright.me/2018/07/create-a-raspberry-pi-vpn-server-using-l2tpipsec/)

<a name="debian-10-note"></a>
\* Debian 11/10 用户需要 [使用标准的 Linux 内核](docs/clients-zh.md#debian-10-内核)。   
<a name="centos-8-note"></a>
\*\* 对 CentOS Linux 8 的支持 [已经结束](https://www.centos.org/centos-linux-eol/)。你可以另外使用比如 Rocky Linux 或者 AlmaLinux。

:warning: **不要** 在你的 PC 或者 Mac 上运行这些脚本！它们只能用在服务器上！

## 安装说明

首先，更新你的系统：运行 `sudo apt-get update && sudo apt-get dist-upgrade` (Ubuntu/Debian) 或者 `sudo yum update` 并重启。这一步是可选的，但推荐。

要安装 VPN，请从以下选项中选择一个：

<details open>
<summary>
选项 1: 使用脚本随机生成的 VPN 登录凭证（完成后会在屏幕上显示）。
</summary>

```bash
wget https://git.io/vpnsetup -qO vpn.sh && sudo sh vpn.sh
```

在安装成功之后，推荐 [配置 IKEv2](docs/ikev2-howto-zh.md)：

```bash
# 使用默认选项配置 IKEv2
sudo ikev2.sh --auto
# 或者你也可以自定义 IKEv2 选项
sudo ikev2.sh
```
</details>

<details>
<summary>
选项 2: 编辑脚本并提供你自己的 VPN 登录凭证。
</summary>

```bash
wget https://git.io/vpnsetup -nv -O vpn.sh
nano -w vpn.sh
[替换为你自己的值： YOUR_IPSEC_PSK, YOUR_USERNAME 和 YOUR_PASSWORD]
sudo sh vpn.sh
```

**注：** 一个安全的 IPsec PSK 应该至少包含 20 个随机字符。

在安装成功之后，推荐 [配置 IKEv2](docs/ikev2-howto-zh.md)：

```bash
# 使用默认选项配置 IKEv2
sudo ikev2.sh --auto
# 或者你也可以自定义 IKEv2 选项
sudo ikev2.sh
```
</details>

<details>
<summary>
选项 3: 将你自己的 VPN 登录凭证定义为环境变量。
</summary>

```bash
# 所有变量值必须用 '单引号' 括起来
# *不要* 在值中使用这些字符：  \ " '
wget https://git.io/vpnsetup -nv -O vpn.sh
sudo VPN_IPSEC_PSK='你的IPsec预共享密钥' \
VPN_USER='你的VPN用户名' \
VPN_PASSWORD='你的VPN密码' \
sh vpn.sh
```

在安装成功之后，推荐 [配置 IKEv2](docs/ikev2-howto-zh.md)：

```bash
# 使用默认选项配置 IKEv2
sudo ikev2.sh --auto
# 或者你也可以自定义 IKEv2 选项
sudo ikev2.sh
```
</details>

<details>
<summary>
如果无法通过 wget 下载，点这里查看解决方案。
</summary>

你也可以使用 `curl` 下载。例如：

```bash
curl -fsSL https://git.io/vpnsetup -o vpn.sh
sudo sh vpn.sh
```

或者，打开 [vpnsetup.sh](vpnsetup.sh) 并点击右方的 `Raw` 按钮。按快捷键 `Ctrl/Cmd+A` 全选，`Ctrl/Cmd+C` 复制，然后粘贴到你喜欢的编辑器。
</details>

## 下一步

配置你的计算机或其它设备使用 VPN。请参见：

[**IKEv2 VPN 配置和使用指南**](docs/ikev2-howto-zh.md)

[**配置 IPsec/L2TP VPN 客户端**](docs/clients-zh.md)

[**配置 IPsec/XAuth ("Cisco IPsec") VPN 客户端**](docs/clients-xauth-zh.md)

如果在连接过程中遇到错误，请参见 [故障排除](docs/clients-zh.md#故障排除)。

开始使用自己的专属 VPN! :sparkles::tada::rocket::sparkles:

## 重要提示

*其他语言版本: [English](README.md#important-notes), [简体中文](README-zh.md#重要提示)。*

**Windows 用户** 对于 IPsec/L2TP 模式，在首次连接之前需要 [修改注册表](docs/clients-zh.md#windows-错误-809)，以解决 VPN 服务器或客户端与 NAT（比如家用路由器）的兼容问题。

同一个 VPN 账户可以在你的多个设备上使用。但是由于 IPsec/L2TP 的局限性，如果需要连接在同一个 NAT（比如家用路由器）后面的多个设备，你必须使用 [IKEv2](docs/ikev2-howto-zh.md) 或者 [IPsec/XAuth](docs/clients-xauth-zh.md) 模式。

要查看或更改 VPN 用户账户，请参见 [管理 VPN 用户](docs/manage-users-zh.md)。该文档包含辅助脚本，以方便管理 VPN 用户。

对于有外部防火墙的服务器（比如 [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)），请为 VPN 打开 UDP 端口 500 和 4500。阿里云用户请参见 [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433)。

在 VPN 已连接时，客户端配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，请参见 [高级用法](docs/advanced-usage-zh.md)。

使用内核支持有助于提高 IPsec/L2TP 性能。它在所有 [受支持的系统](#系统要求) 上可用。Ubuntu 系统需要安装 `linux-modules-extra-$(uname -r)`（或者 `linux-image-extra`）软件包并运行 `service xl2tpd restart`。

这些脚本在更改现有的配置文件之前会先做备份，使用 `.old-日期-时间` 为文件名后缀。

## 升级Libreswan

使用以下命令更新你的 VPN 服务器上的 [Libreswan](https://libreswan.org)（[更新日志](https://github.com/libreswan/libreswan/blob/main/CHANGES) | [通知列表](https://lists.libreswan.org/mailman/listinfo/swan-announce)）。

```bash
wget https://git.io/vpnupgrade -qO vpnup.sh && sudo sh vpnup.sh
```

当前支持的 Libreswan 最新版本是 `4.6`。查看已安装版本：`ipsec --version`。

**注：** `xl2tpd` 可以使用系统的软件包管理器进行更新，例如 Ubuntu/Debian 上的 `apt-get`。

## 管理 VPN 用户

请参见 [管理 VPN 用户](docs/manage-users-zh.md)。

- [查看或更改 IPsec PSK](docs/manage-users-zh.md#查看或更改-ipsec-psk)
- [查看 VPN 用户](docs/manage-users-zh.md#查看-vpn-用户)
- [使用辅助脚本管理 VPN 用户](docs/manage-users-zh.md#使用辅助脚本管理-vpn-用户)
- [手动管理 VPN 用户](docs/manage-users-zh.md#手动管理-vpn-用户)

## 高级用法

请参见 [高级用法](docs/advanced-usage-zh.md)。

- [使用其他的 DNS 服务器](docs/advanced-usage-zh.md#使用其他的-dns-服务器)
- [域名和更改服务器 IP](docs/advanced-usage-zh.md#域名和更改服务器-ip)
- [仅限 IKEv2 的 VPN](docs/advanced-usage-zh.md#仅限-ikev2-的-vpn)
- [VPN 内网 IP 和流量](docs/advanced-usage-zh.md#vpn-内网-ip-和流量)
- [转发端口到 VPN 客户端](docs/advanced-usage-zh.md#转发端口到-vpn-客户端)
- [VPN 分流](docs/advanced-usage-zh.md#vpn-分流)
- [访问 VPN 服务器的网段](docs/advanced-usage-zh.md#访问-vpn-服务器的网段)
- [更改 IPTables 规则](docs/advanced-usage-zh.md#更改-iptables-规则)
- [部署 Google BBR 拥塞控制算法](docs/advanced-usage-zh.md#部署-google-bbr-拥塞控制算法)

## 卸载说明

请参见 [卸载 VPN](docs/uninstall-zh.md)。

- [使用辅助脚本卸载 VPN](docs/uninstall-zh.md#使用辅助脚本卸载-vpn)
- [手动卸载 VPN](docs/uninstall-zh.md#手动卸载-vpn)

## 问题和反馈

- 如果你对文档或 VPN 脚本有改进建议，请提交一个 [改进建议](https://github.com/hwdsl2/setup-ipsec-vpn/issues/new/choose)，或者欢迎提交 [Pull request](https://github.com/hwdsl2/setup-ipsec-vpn/pulls)。
- 如果你发现了一个可重复的程序漏洞，请为 [IPsec VPN](https://github.com/libreswan/libreswan/issues?q=is%3Aissue) 或者 [VPN 脚本](https://github.com/hwdsl2/setup-ipsec-vpn/issues/new/choose) 提交一个错误报告。
- 有问题需要提问？请先搜索 [已有的 issues](https://github.com/hwdsl2/setup-ipsec-vpn/issues?q=is%3Aissue) 以及在 [这个 Gist](https://gist.github.com/hwdsl2/9030462#comments) 和 [我的博客](https://blog.ls20.com/ipsec-l2tp-vpn-auto-setup-for-ubuntu-12-04-on-amazon-ec2/#disqus_thread) 上已有的留言。
- VPN 的相关问题可在 [Libreswan](https://lists.libreswan.org/mailman/listinfo/swan) 或 [strongSwan](https://lists.strongswan.org/mailman/listinfo/users) 邮件列表提问，或者参考这些网站：[[1]](https://libreswan.org/wiki/Main_Page) [[2]](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-securing_virtual_private_networks) [[3]](https://wiki.strongswan.org/projects/strongswan/wiki/UserDocumentation) [[4]](https://wiki.gentoo.org/wiki/IPsec_L2TP_VPN_server) [[5]](https://wiki.archlinux.org/index.php/Openswan_L2TP/IPsec_VPN_client_setup)。

## 授权协议

版权所有 (C) 2014-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
基于 [Thomas Sarlandie 的工作](https://github.com/sarfata/voodooprivacy) (版权所有 2012)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
