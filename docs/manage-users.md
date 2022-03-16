# Manage VPN Users

*Read this in other languages: [English](manage-users.md), [简体中文](manage-users-zh.md).*

By default, a single user account for VPN login is created. If you wish to view or manage users for the IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes, read this document. For IKEv2, see [Manage client certificates](ikev2-howto.md#manage-client-certificates).

* [Manage VPN users using helper scripts](#manage-vpn-users-using-helper-scripts)
* [View VPN users](#view-vpn-users)
* [View or update the IPsec PSK](#view-or-update-the-ipsec-psk)
* [Manually manage VPN users](#manually-manage-vpn-users)

## Manage VPN users using helper scripts

*Read this in other languages: [English](manage-users.md#manage-vpn-users-using-helper-scripts), [简体中文](manage-users-zh.md#使用辅助脚本管理-vpn-用户).*

You may use helper scripts to [add](../extras/add_vpn_user.sh), [delete](../extras/del_vpn_user.sh) or [update all](../extras/update_vpn_users.sh) VPN users for both IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes. For IKEv2 mode, please instead see [Manage client certificates](ikev2-howto.md#manage-client-certificates).

**Note:** Replace command arguments below with your own values. VPN users are stored in `/etc/ppp/chap-secrets` and `/etc/ipsec.d/passwd`. The scripts will backup these files before making changes, with `.old-date-time` suffix.

### Add or edit a VPN user

Add a new VPN user, or update an existing VPN user with a new password.

Run the script and follow the prompts:

```bash
sudo addvpnuser.sh
```

<details>
<summary>
Error: "sudo: addvpnuser.sh: command not found".
</summary>

This is normal if you used an older version of the VPN setup script. First, download the helper script:

```bash
wget -nv -O /opt/src/addvpnuser.sh https://bit.ly/addvpnuser
chmod +x /opt/src/addvpnuser.sh && ln -s /opt/src/addvpnuser.sh /usr/bin
```

Then run the script using the instructions.
</details>

Alternatively, you can run the script with arguments:

```bash
# All values MUST be placed inside 'single quotes'
# DO NOT use these special characters within values: \ " '
sudo addvpnuser.sh 'username_to_add' 'password'
# OR
sudo addvpnuser.sh 'username_to_update' 'new_password'
```

### Delete a VPN user

Delete the specified VPN user.

Run the script and follow the prompts:

```bash
sudo delvpnuser.sh
```

<details>
<summary>
Error: "sudo: delvpnuser.sh: command not found".
</summary>

This is normal if you used an older version of the VPN setup script. First, download the helper script:

```bash
wget -nv -O /opt/src/delvpnuser.sh https://bit.ly/delvpnuser
chmod +x /opt/src/delvpnuser.sh && ln -s /opt/src/delvpnuser.sh /usr/bin
```

Then run the script using the instructions.
</details>

Alternatively, you can run the script with arguments:

```bash
# All values MUST be placed inside 'single quotes'
# DO NOT use these special characters within values: \ " '
sudo delvpnuser.sh 'username_to_delete'
```

### Update all VPN users

Remove all existing VPN users and replace with the list of users you specify.

First, download the script:

```bash
wget -nv -O updatevpnusers.sh https://bit.ly/updatevpnusers
```

To use this script, choose one of the following options:

**Important:** This script will remove **ALL** existing VPN users and replace them with the list of users you specify. Therefore, you must include any existing user(s) you want to keep in the variables below.

**Option 1:** Edit the script and enter VPN user details:

```bash
nano -w updatevpnusers.sh
[Replace with your own values: YOUR_USERNAMES and YOUR_PASSWORDS]
sudo bash updatevpnusers.sh
```

**Option 2:** Define VPN user details as environment variables:

```bash
# List of VPN usernames and passwords, separated by spaces
# All values MUST be placed inside 'single quotes'
# DO NOT use these special characters within values: \ " '
sudo \
VPN_USERS='username1 username2 ...' \
VPN_PASSWORDS='password1 password2 ...' \
bash updatevpnusers.sh
```

## View VPN users

By default, the VPN setup scripts will create the same VPN user for both IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes.

For IPsec/L2TP, VPN users are specified in `/etc/ppp/chap-secrets`. The format of this file is:

```bash
"username1"  l2tpd  "password1"  *
"username2"  l2tpd  "password2"  *
... ...
```

For IPsec/XAuth ("Cisco IPsec"), VPN users are specified in `/etc/ipsec.d/passwd`. Passwords in this file are salted and hashed. See [Manually manage VPN users](#manually-manage-vpn-users) for more details.

## View or update the IPsec PSK

The IPsec PSK (pre-shared key) is stored in `/etc/ipsec.secrets`. All VPN users will share the same IPsec PSK. The format of this file is:

```bash
%any  %any  : PSK "your_ipsec_pre_shared_key"
```

To change to a new PSK, just edit this file. DO NOT use these special characters within values: `\ " '`

You must restart services when finished:

```bash
service ipsec restart
service xl2tpd restart
```

## Manually manage VPN users

For IPsec/L2TP, VPN users are specified in `/etc/ppp/chap-secrets`. The format of this file is:

```bash
"username1"  l2tpd  "password1"  *
"username2"  l2tpd  "password2"  *
... ...
```

You can add more users, use one line for each user. DO NOT use these special characters within values: `\ " '`

For IPsec/XAuth ("Cisco IPsec"), VPN users are specified in `/etc/ipsec.d/passwd`. The format of this file is:

```bash
username1:password1hashed:xauth-psk
username2:password2hashed:xauth-psk
... ...
```

Passwords in this file are salted and hashed. This step can be done using e.g. the `openssl` utility:

```bash
# The output will be password1hashed
# Put your password inside 'single quotes'
openssl passwd -1 'password1'
```

## License

Copyright (C) 2016-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)  
Attribution required: please include my name in any derivative and let me know how you have improved it!
