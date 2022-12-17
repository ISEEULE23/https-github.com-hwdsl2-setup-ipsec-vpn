[English](clients-xauth.md) | [中文](clients-xauth-zh.md)

# Configure IPsec/XAuth VPN Clients

After [setting up your own VPN server](https://github.com/hwdsl2/setup-ipsec-vpn), follow these steps to configure your devices. IPsec/XAuth ("Cisco IPsec") is natively supported by Android, iOS and OS X. There is no additional software to install. Windows users can use the free [Shrew Soft client](https://www.shrew.net/download/vpn). In case you are unable to connect, first check to make sure the VPN credentials were entered correctly.

IPsec/XAuth mode is also called "Cisco IPsec". This mode is generally **faster than** IPsec/L2TP with less overhead.

---
* Platforms
  * [Windows](#windows)
  * [OS X (macOS)](#os-x)
  * [Android](#android)
  * [iOS (iPhone/iPad)](#ios)
  * [Linux](#linux)

Like this project? [:heart: Sponsor](https://github.com/sponsors/hwdsl2?metadata_o=x) or [:coffee: Support](https://ko-fi.com/hwdsl2) and access [extra content](https://ko-fi.com/post/Support-this-project-and-get-access-to-supporter-o-O5O7FVF8J).

## Windows

> You may also connect using [IKEv2](ikev2-howto.md) (recommended) or [IPsec/L2TP](clients.md) mode. No additional software is required.

1. Download and install the free [Shrew Soft VPN client](https://www.shrew.net/download/vpn). When prompted during install, select **Standard Edition**.   
   **Note:** This VPN client does NOT support Windows 10/11.
1. Click Start Menu -> All Programs -> ShrewSoft VPN Client -> VPN Access Manager
1. Click the **Add (+)** button on toolbar.
1. Enter `Your VPN Server IP` in the **Host Name or IP Address** field.
1. Click the **Authentication** tab. Select **Mutual PSK + XAuth** from the **Authentication Method** drop-down menu.
1. Under the **Local Identity** sub-tab, select **IP Address** from the **Identification Type** drop-down menu.
1. Click the **Credentials** sub-tab. Enter `Your VPN IPsec PSK` in the **Pre Shared Key** field.
1. Click the **Phase 1** tab. Select **main** from the **Exchange Type** drop-down menu.
1. Click the **Phase 2** tab. Select **sha1** from the **HMAC Algorithm** drop-down menu.
1. Click **Save** to save the VPN connection details.
1. Select the new VPN connection. Click the **Connect** button on toolbar.
1. Enter `Your VPN Username` in the **Username** field.
1. Enter `Your VPN Password` in the **Password** field.
1. Click **Connect**.

Once connected, you will see **tunnel enabled** in the VPN Connect status window. Click the "Network" tab, and confirm that **Established - 1** is displayed under "Security Associations". You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](clients.md#troubleshooting).

## OS X

> You may also connect using [IKEv2](ikev2-howto.md) (recommended) or [IPsec/L2TP](clients.md) mode.

1. Open System Preferences and go to the Network section.
1. Click the **+** button in the lower-left corner of the window.
1. Select **VPN** from the **Interface** drop-down menu.
1. Select **Cisco IPSec** from the **VPN Type** drop-down menu.
1. Enter anything you like for the **Service Name**.
1. Click **Create**.
1. Enter `Your VPN Server IP` for the **Server Address**.
1. Enter `Your VPN Username` for the **Account Name**.
1. Enter `Your VPN Password` for the **Password**.
1. Click the **Authentication Settings** button.
1. In the **Machine Authentication** section, select the **Shared Secret** radio button and enter `Your VPN IPsec PSK`.
1. Leave the **Group Name** field blank.
1. Click **OK**.
1. Check the **Show VPN status in menu bar** checkbox.
1. Click **Apply** to save the VPN connection information.

To connect to the VPN: Use the menu bar icon, or go to the Network section of System Preferences, select the VPN and choose **Connect**. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](clients.md#troubleshooting).

## Android

**Important:** Android users should instead connect using [IKEv2 mode](ikev2-howto.md) (recommended), which is more secure. Android 12+ only supports IKEv2 mode. The native VPN client in Android uses the less secure `modp1024` (DH group 2) for the IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes.

If you still want to connect using IPsec/XAuth mode, you must first edit `/etc/ipsec.conf` on the VPN server. Find the line `ike=...` and append `,aes256-sha2;modp1024,aes128-sha1;modp1024` at the end. Save the file and run `sudo service ipsec restart`.

Docker users: Add `VPN_ENABLE_MODP1024=yes` to [your env file](https://github.com/hwdsl2/docker-ipsec-vpn-server#how-to-use-this-image), then re-create the Docker container.

After that, follow the steps below on your Android device:

1. Launch the **Settings** application.
1. Tap "Network & internet". Or, if using Android 7 or earlier, tap **More...** in the **Wireless & networks** section.
1. Tap **VPN**.
1. Tap **Add VPN Profile** or the **+** icon at top-right of screen.
1. Enter anything you like in the **Name** field.
1. Select **IPSec Xauth PSK** in the **Type** drop-down menu.
1. Enter `Your VPN Server IP` in the **Server address** field.
1. Leave the **IPSec identifier** field blank.
1. Enter `Your VPN IPsec PSK` in the **IPSec pre-shared key** field.
1. Tap **Save**.
1. Tap the new VPN connection.
1. Enter `Your VPN Username` in the **Username** field.
1. Enter `Your VPN Password` in the **Password** field.
1. Check the **Save account information** checkbox.
1. Tap **Connect**.

Once connected, you will see a VPN icon in the notification bar. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](clients.md#troubleshooting).

## iOS

> You may also connect using [IKEv2](ikev2-howto.md) (recommended) or [IPsec/L2TP](clients.md) mode.

1. Go to Settings -> General -> VPN.
1. Tap **Add VPN Configuration...**.
1. Tap **Type**. Select **IPSec** and go back.
1. Tap **Description** and enter anything you like.
1. Tap **Server** and enter `Your VPN Server IP`.
1. Tap **Account** and enter `Your VPN Username`.
1. Tap **Password** and enter `Your VPN Password`.
1. Leave the **Group Name** field blank.
1. Tap **Secret** and enter `Your VPN IPsec PSK`.
1. Tap **Done**.
1. Slide the **VPN** switch ON.

Once connected, you will see a VPN icon in the status bar. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](clients.md#troubleshooting).

## Linux

> You may also connect using [IKEv2](ikev2-howto.md) mode (recommended).

### Fedora and CentOS

Fedora 28 (and newer) and CentOS 8/7 users can install the `NetworkManager-libreswan-gnome` package using `yum`, then configure the IPsec/XAuth VPN client using the GUI.

1. Go to Settings -> Network -> VPN. Click the **+** button.
1. Select **IPsec based VPN**.
1. Enter anything you like in the **Name** field.
1. Enter `Your VPN Server IP` for the **Gateway**.
1. Select **IKEv1 (XAUTH)** in the **Type** drop-down menu.
1. Enter `Your VPN Username` for the **User name**.
1. Right-click the **?** in the **User password** field, select **Store the password only for this user**.
1. Enter `Your VPN Password` for the **User password**.
1. Leave the **Group name** field blank.
1. Right-click the **?** in the **Secret** field, select **Store the password only for this user**.
1. Enter `Your VPN IPsec PSK` for the **Secret**.
1. Leave the **Remote ID** field blank.
1. Click **Add** to save the VPN connection information.
1. Turn the **VPN** switch ON.

Once connected, you can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

### Other Linux

Other Linux users can connect using [IPsec/L2TP](clients.md#linux) mode.

## Credits

This document was adapted from the [Streisand](https://github.com/StreisandEffect/streisand) project, maintained by Joshua Lund and contributors.

## License

Note: This license applies to this document only.

Copyright (C) 2016-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
Based on [the work of Joshua Lund](https://github.com/StreisandEffect/streisand/blob/6aa6b6b2735dd829ca8c417d72eb2768a89b6639/playbooks/roles/l2tp-ipsec/templates/instructions.md.j2) (Copyright 2014-2016)

This program is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl.html) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
