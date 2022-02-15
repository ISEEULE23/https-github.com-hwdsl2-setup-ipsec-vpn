# 管理 VPN 用户

*其他语言版本: [English](manage-users.md), [简体中文](manage-users-zh.md)。*

在默认情况下，将只创建一个用于 VPN 登录的用户账户。如果你需要查看或管理 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 模式的用户，请阅读本文档。对于 IKEv2，参见 [管理客户端证书](ikev2-howto-zh.md#管理客户端证书)。

* [查看或更改 IPsec PSK](#查看或更改-ipsec-psk)
* [查看 VPN 用户](#查看-vpn-用户)
* [使用辅助脚本管理 VPN 用户](#使用辅助脚本管理-vpn-用户)
* [手动管理 VPN 用户](#手动管理-vpn-用户)

## 查看或更改 IPsec PSK

IPsec PSK（预共享密钥）保存在文件 `/etc/ipsec.secrets`。所有的 VPN 用户将共享同一个 IPsec PSK。该文件的格式如下：

```bash
%any  %any  : PSK "你的IPsec预共享密钥"
```

如果要更换一个新的 PSK，可以编辑此文件。**不要**在值中使用这些字符：`\ " '`

完成后必须重启服务：

```bash
service ipsec restart
service xl2tpd restart
```

## 查看 VPN 用户

在默认情况下，VPN 安装脚本将为 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 模式创建相同的用户。

对于 IPsec/L2TP，VPN 用户信息保存在文件 `/etc/ppp/chap-secrets`。该文件的格式如下：

```bash
"用户名1"  l2tpd  "密码1"  *
"用户名2"  l2tpd  "密码2"  *
... ...
```

对于 IPsec/XAuth ("Cisco IPsec")，VPN 用户信息保存在文件 `/etc/ipsec.d/passwd`。这个文件中的密码以加盐哈希值的形式保存。更多详情请见 [手动管理 VPN 用户](#手动管理-vpn-用户)。

## 使用辅助脚本管理 VPN 用户

你可以使用这些脚本来更方便地管理 VPN 用户：[add_vpn_user.sh](../extras/add_vpn_user.sh), [del_vpn_user.sh](../extras/del_vpn_user.sh) 和 [update_vpn_users.sh](../extras/update_vpn_users.sh)。它们将同时更新 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 模式的用户。将下面的命令的参数换成你自己的值。对于 IKEv2，参见 [管理客户端证书](ikev2-howto-zh.md#管理客户端证书)。

**注：** VPN 用户信息保存在文件 `/etc/ppp/chap-secrets` 和 `/etc/ipsec.d/passwd`。脚本在修改这些文件之前会先做备份，使用 `.old-日期-时间` 为后缀。

### 添加或更改一个 VPN 用户

添加一个新 VPN 用户，或者为一个已有的 VPN 用户更改密码。

```bash
# 下载脚本
wget -nv -O add_vpn_user.sh https://bit.ly/addvpnuser
# 运行脚本并按提示操作
sudo bash add_vpn_user.sh
```

另外，你也可以在添加参数的情况下运行脚本：

```bash
# 所有变量值必须用 '单引号' 括起来
# *不要* 在值中使用这些字符：  \ " '
sudo bash add_vpn_user.sh '要添加的用户名' '密码'
# 或者
sudo bash add_vpn_user.sh '要更新的用户名' '新密码'
```

### 删除一个 VPN 用户

删除指定的 VPN 用户。

```bash
# 下载脚本
wget -nv -O del_vpn_user.sh https://bit.ly/delvpnuser
# 运行脚本并按提示操作
sudo bash del_vpn_user.sh
```

另外，你也可以在添加参数的情况下运行脚本：

```bash
# 所有变量值必须用 '单引号' 括起来
# *不要* 在值中使用这些字符：  \ " '
sudo bash del_vpn_user.sh '要删除的用户名'
```

### 更新所有的 VPN 用户

移除所有的 VPN 用户并替换为你指定的列表中的用户。

```bash
# 下载脚本
wget -nv -O update_vpn_users.sh https://bit.ly/updatevpnusers
```

要使用这个脚本，从以下选项中选择一个：

**重要：** 这个脚本会将你当前**所有的** VPN 用户移除并替换为你指定的列表中的用户。如果你需要保留已有的 VPN 用户，则必须将它们包含在下面的变量中。

**选项 1:** 编辑脚本并输入 VPN 用户信息：

```bash
nano -w update_vpn_users.sh
[替换为你自己的值： YOUR_USERNAMES 和 YOUR_PASSWORDS]
sudo bash update_vpn_users.sh
```

**选项 2:** 将 VPN 用户信息定义为环境变量：

```bash
# VPN用户名和密码列表，用空格分隔
# 所有变量值必须用 '单引号' 括起来
# *不要* 在值中使用这些字符：  \ " '
sudo \
VPN_USERS='用户名1 用户名2 ...' \
VPN_PASSWORDS='密码1 密码2 ...' \
bash update_vpn_users.sh
```

## 手动管理 VPN 用户

对于 IPsec/L2TP，VPN 用户信息保存在文件 `/etc/ppp/chap-secrets`。该文件的格式如下：

```bash
"用户名1"  l2tpd  "密码1"  *
"用户名2"  l2tpd  "密码2"  *
... ...
```

你可以添加更多用户，每个用户对应文件中的一行。**不要**在值中使用这些字符：`\ " '`

对于 IPsec/XAuth ("Cisco IPsec")，VPN 用户信息保存在文件 `/etc/ipsec.d/passwd`。该文件的格式如下：

```bash
用户名1:密码1的加盐哈希值:xauth-psk
用户名2:密码2的加盐哈希值:xauth-psk
... ...
```

这个文件中的密码以加盐哈希值的形式保存。该步骤可以借助比如 `openssl` 工具来完成：

```bash
# 以下命令的输出为：密码1的加盐哈希值
# 将你的密码用 '单引号' 括起来
openssl passwd -1 '密码1'
```

## 授权协议

版权所有 (C) 2016-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
