[English](clients.md) | [中文](clients-zh.md)

# Configure IPsec/L2TP VPN Clients

After [setting up your own VPN server](https://github.com/hwdsl2/setup-ipsec-vpn), follow these steps to configure your devices. IPsec/L2TP is natively supported by Android, iOS, OS X, and Windows. There is no additional software to install. Setup should only take a few minutes. In case you are unable to connect, first check to make sure the VPN credentials were entered correctly.

---
* Platforms
  * [Windows](#windows)
  * [OS X (macOS)](#os-x)
  * [Android](#android)
  * [iOS (iPhone/iPad)](#ios)
  * [Chrome OS (Chromebook)](#chrome-os)
  * [Linux](#linux)
* [Troubleshooting](#troubleshooting)

Like this project? [:heart: Sponsor](https://github.com/sponsors/hwdsl2?metadata_o=l) or [:coffee: Support](https://ko-fi.com/hwdsl2) and access [extra content](https://ko-fi.com/post/Support-this-project-and-get-access-to-supporter-o-O5O7FVF8J).

## Windows

> You may also connect using [IKEv2](ikev2-howto.md) mode (recommended).

### Windows 11

1. Right-click on the wireless/network icon in your system tray.
1. Select **Network and Internet settings**, then on the page that opens, click **VPN**.
1. Click the **Add VPN** button.
1. Select **Windows (built-in)** in the **VPN provider** drop-down menu.
1. Enter anything you like in the **Connection name** field.
1. Enter `Your VPN Server IP` in the **Server name or address** field.
1. Select **L2TP/IPsec with pre-shared key** in the **VPN type** drop-down menu.
1. Enter `Your VPN IPsec PSK` in the **Pre-shared key** field.
1. Enter `Your VPN Username` in the **User name** field.
1. Enter `Your VPN Password` in the **Password** field.
1. Check the **Remember my sign-in info** checkbox.
1. Click **Save** to save the VPN connection details.

**Note:** This [one-time registry change](#windows-error-809) is required if the VPN server and/or client is behind NAT (e.g. home router).

To connect to the VPN: Click the **Connect** button, or click on the wireless/network icon in your system tray, click **VPN**, then select the new VPN entry and click **Connect**. If prompted, enter `Your VPN Username` and `Password`, then click **OK**. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

### Windows 10 and 8

1. Right-click on the wireless/network icon in your system tray.
1. Select **Open Network & Internet settings**, then on the page that opens, click **Network and Sharing Center**.
1. Click **Set up a new connection or network**.
1. Select **Connect to a workplace** and click **Next**.
1. Click **Use my Internet connection (VPN)**.
1. Enter `Your VPN Server IP` in the **Internet address** field.
1. Enter anything you like in the **Destination name** field, and then click **Create**.
1. Return to **Network and Sharing Center**. On the left, click **Change adapter settings**.
1. Right-click on the new VPN entry and choose **Properties**.
1. Click the **Security** tab. Select "Layer 2 Tunneling Protocol with IPsec (L2TP/IPSec)" for the **Type of VPN**.
1. Click **Allow these protocols**. Check the "Challenge Handshake Authentication Protocol (CHAP)" and "Microsoft CHAP Version 2 (MS-CHAP v2)" checkboxes.
1. Click the **Advanced settings** button.
1. Select **Use preshared key for authentication** and enter `Your VPN IPsec PSK` for the **Key**.
1. Click **OK** to close the **Advanced settings**.
1. Click **OK** to save the VPN connection details.

**Note:** This [one-time registry change](#windows-error-809) is required if the VPN server and/or client is behind NAT (e.g. home router).

To connect to the VPN: Click on the wireless/network icon in your system tray, select the new VPN entry, and click **Connect**. If prompted, enter `Your VPN Username` and `Password`, then click **OK**. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

Alternatively, instead of following the steps above, you may create the VPN connection using these Windows PowerShell commands. Replace `Your VPN Server IP` and `Your VPN IPsec PSK` with your own values, enclosed in single quotes:

```console
# Disable persistent command history
Set-PSReadlineOption –HistorySaveStyle SaveNothing
# Create VPN connection
Add-VpnConnection -Name 'My IPsec VPN' -ServerAddress 'Your VPN Server IP' ^
  -L2tpPsk 'Your VPN IPsec PSK' -TunnelType L2tp -EncryptionLevel Required ^
  -AuthenticationMethod Chap,MSChapv2 -Force -RememberCredential -PassThru
# Ignore the data encryption warning (data is encrypted in the IPsec tunnel)
```

### Windows 7, Vista and XP

1. Click on the Start Menu and go to the Control Panel.
1. Go to the **Network and Internet** section.
1. Click **Network and Sharing Center**.
1. Click **Set up a new connection or network**.
1. Select **Connect to a workplace** and click **Next**.
1. Click **Use my Internet connection (VPN)**.
1. Enter `Your VPN Server IP` in the **Internet address** field.
1. Enter anything you like in the **Destination name** field.
1. Check the **Don't connect now; just set it up so I can connect later** checkbox.
1. Click **Next**.
1. Enter `Your VPN Username` in the **User name** field.
1. Enter `Your VPN Password` in the **Password** field.
1. Check the **Remember this password** checkbox.
1. Click **Create**, and then **Close**.
1. Return to **Network and Sharing Center**. On the left, click **Change adapter settings**.
1. Right-click on the new VPN entry and choose **Properties**.
1. Click the **Options** tab and uncheck **Include Windows logon domain**.
1. Click the **Security** tab. Select "Layer 2 Tunneling Protocol with IPsec (L2TP/IPSec)" for the **Type of VPN**.
1. Click **Allow these protocols**. Check the "Challenge Handshake Authentication Protocol (CHAP)" and "Microsoft CHAP Version 2 (MS-CHAP v2)" checkboxes.
1. Click the **Advanced settings** button.
1. Select **Use preshared key for authentication** and enter `Your VPN IPsec PSK` for the **Key**.
1. Click **OK** to close the **Advanced settings**.
1. Click **OK** to save the VPN connection details.

**Note:** This [one-time registry change](#windows-error-809) is required if the VPN server and/or client is behind NAT (e.g. home router).

To connect to the VPN: Click on the wireless/network icon in your system tray, select the new VPN entry, and click **Connect**. If prompted, enter `Your VPN Username` and `Password`, then click **OK**. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

## OS X

> You may also connect using [IKEv2](ikev2-howto.md) (recommended) or [IPsec/XAuth](clients-xauth.md) mode.

1. Open System Preferences and go to the Network section.
1. Click the **+** button in the lower-left corner of the window.
1. Select **VPN** from the **Interface** drop-down menu.
1. Select **L2TP over IPSec** from the **VPN Type** drop-down menu.
1. Enter anything you like for the **Service Name**.
1. Click **Create**.
1. Enter `Your VPN Server IP` for the **Server Address**.
1. Enter `Your VPN Username` for the **Account Name**.
1. Click the **Authentication Settings** button.
1. In the **User Authentication** section, select the **Password** radio button and enter `Your VPN Password`.
1. In the **Machine Authentication** section, select the **Shared Secret** radio button and enter `Your VPN IPsec PSK`.
1. Click **OK**.
1. Check the **Show VPN status in menu bar** checkbox.
1. **(Important)** Click the **Advanced** button and make sure the **Send all traffic over VPN connection** checkbox is checked.
1. **(Important)** Click the **TCP/IP** tab, and make sure **Link-local only** is selected in the **Configure IPv6** section.
1. Click **OK** to close the Advanced settings, and then click **Apply** to save the VPN connection information.

To connect to the VPN: Use the menu bar icon, or go to the Network section of System Preferences, select the VPN and choose **Connect**. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

## Android

**Important:** Android users should instead connect using [IKEv2 mode](ikev2-howto.md) (recommended), which is more secure. Android 12+ only supports IKEv2 mode. The native VPN client in Android uses the less secure `modp1024` (DH group 2) for the IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes.

If you still want to connect using IPsec/L2TP mode, you must first edit `/etc/ipsec.conf` on the VPN server. Find the line `ike=...` and append `,aes256-sha2;modp1024,aes128-sha1;modp1024` at the end. Save the file and run `sudo service ipsec restart`.

Docker users: Add `VPN_ENABLE_MODP1024=yes` to [your env file](https://github.com/hwdsl2/docker-ipsec-vpn-server#how-to-use-this-image), then re-create the Docker container.

After that, follow the steps below on your Android device:

1. Launch the **Settings** application.
1. Tap "Network & internet". Or, if using Android 7 or earlier, tap **More...** in the **Wireless & networks** section.
1. Tap **VPN**.
1. Tap **Add VPN Profile** or the **+** icon at top-right of screen.
1. Enter anything you like in the **Name** field.
1. Select **L2TP/IPSec PSK** in the **Type** drop-down menu.
1. Enter `Your VPN Server IP` in the **Server address** field.
1. Leave the **L2TP secret** field blank.
1. Leave the **IPSec identifier** field blank.
1. Enter `Your VPN IPsec PSK` in the **IPSec pre-shared key** field.
1. Tap **Save**.
1. Tap the new VPN connection.
1. Enter `Your VPN Username` in the **Username** field.
1. Enter `Your VPN Password` in the **Password** field.
1. Check the **Save account information** checkbox.
1. Tap **Connect**.

Once connected, you will see a VPN icon in the notification bar. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

## iOS

> You may also connect using [IKEv2](ikev2-howto.md) (recommended) or [IPsec/XAuth](clients-xauth.md) mode.

1. Go to Settings -> General -> VPN.
1. Tap **Add VPN Configuration...**.
1. Tap **Type**. Select **L2TP** and go back.
1. Tap **Description** and enter anything you like.
1. Tap **Server** and enter `Your VPN Server IP`.
1. Tap **Account** and enter `Your VPN Username`.
1. Tap **Password** and enter `Your VPN Password`.
1. Tap **Secret** and enter `Your VPN IPsec PSK`.
1. Make sure the **Send All Traffic** switch is ON.
1. Tap **Done**.
1. Slide the **VPN** switch ON.

Once connected, you will see a VPN icon in the status bar. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

## Chrome OS

> You may also connect using [IKEv2](ikev2-howto.md) mode (recommended).

1. Go to Settings -> Network.
1. Click **Add connection**, then click **Add built-in VPN**.
1. Enter anything you like for the **Service name**.
1. Select **L2TP/IPsec** in the **Provider type** drop-down menu.
1. Enter `Your VPN Server IP` for the **Server hostname**.
1. Select **Pre-shared key** in the **Authentication type** drop-down menu.
1. Enter `Your VPN Username` for the **Username**.
1. Enter `Your VPN Password` for the **Password**.
1. Enter `Your VPN IPsec PSK` for the **Pre-shared key**.
1. Leave other fields blank.
1. Enable **Save identity and password**.
1. Click **Connect**.

Once connected, you will see a VPN icon overlay on the network status icon. You can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

If you get an error when trying to connect, see [Troubleshooting](#troubleshooting).

## Linux

> You may also connect using [IKEv2](ikev2-howto.md) mode (recommended).

### Ubuntu Linux

Ubuntu 18.04 (and newer) users can install the [network-manager-l2tp-gnome](https://packages.ubuntu.com/search?keywords=network-manager-l2tp-gnome) package using `apt`, then configure the IPsec/L2TP VPN client using the GUI.

1. Go to Settings -> Network -> VPN. Click the **+** button.
1. Select **Layer 2 Tunneling Protocol (L2TP)**.
1. Enter anything you like in the **Name** field.
1. Enter `Your VPN Server IP` for the **Gateway**.
1. Enter `Your VPN Username` for the **User name**.
1. Right-click the **?** in the **Password** field, select **Store the password only for this user**.
1. Enter `Your VPN Password` for the **Password**.
1. Leave the **NT Domain** field blank.
1. Click the **IPsec Settings...** button.
1. Check the **Enable IPsec tunnel to L2TP host** checkbox.
1. Leave the **Gateway ID** field blank.
1. Enter `Your VPN IPsec PSK` for the **Pre-shared key**.
1. Expand the **Advanced** section.
1. Enter `aes128-sha1-modp2048` for the **Phase1 Algorithms**.
1. Enter `aes128-sha1` for the **Phase2 Algorithms**.
1. Click **OK**, then click **Add** to save the VPN connection information.
1. Turn the **VPN** switch ON.

If you get an error when trying to connect, try [this fix](https://github.com/nm-l2tp/NetworkManager-l2tp/blob/2926ea0239fe970ff08cb8a7863f8cb519ece032/README.md#unable-to-establish-l2tp-connection-without-udp-source-port-1701).

Once connected, you can verify that your traffic is being routed properly by [looking up your IP address on Google](https://www.google.com/search?q=my+ip). It should say "Your public IP address is `Your VPN Server IP`".

### Fedora and CentOS

Fedora 28 (and newer) and CentOS 8/7 users can connect using [IPsec/XAuth](clients-xauth.md) mode.

### Other Linux

First check [here](https://github.com/nm-l2tp/NetworkManager-l2tp/wiki/Prebuilt-Packages) to see if the `network-manager-l2tp` and `network-manager-l2tp-gnome` packages are available for your Linux distribution. If yes, install them (select strongSwan) and follow the instructions above. Alternatively, you may [configure Linux VPN clients using the command line](#configure-linux-vpn-clients-using-the-command-line).

## Troubleshooting

*Read this in other languages: [English](clients.md#troubleshooting), [中文](clients-zh.md#故障排除).*

**See also:** [Check logs and VPN status](#check-logs-and-vpn-status), [IKEv2 troubleshooting](ikev2-howto.md#troubleshooting) and [Advanced usage](advanced-usage.md).

* [Windows error 809](#windows-error-809)
* [Windows error 789 or 691](#windows-error-789-or-691)
* [Windows error 628 or 766](#windows-error-628-or-766)
* [Windows 10 connecting](#windows-10-connecting)
* [Windows 10 upgrades](#windows-10-upgrades)
* [Windows DNS leaks and IPv6](#windows-dns-leaks-and-ipv6)
* [Android MTU/MSS issues](#android-mtumss-issues)
* [Android 6 and 7](#android-6-and-7)
* [macOS send traffic over VPN](#macos-send-traffic-over-vpn)
* [iOS 13+ and macOS 10.15/11+](#ios-13-and-macos-101511)
* [iOS/Android sleep mode](#iosandroid-sleep-mode)
* [Debian 11/10 kernel](#debian-1110-kernel)
* [Other errors](#other-errors)
* [Check logs and VPN status](#check-logs-and-vpn-status)

### Windows error 809

> Error 809: The network connection between your computer and the VPN server could not be established because the remote server is not responding. This could be because one of the network devices (e.g, firewalls, NAT, routers, etc) between your computer and the remote server is not configured to allow VPN connections. Please contact your Administrator or your service provider to determine which device may be causing the problem.

**Note:** The registry change below is only required if you use IPsec/L2TP mode to connect to the VPN. It is NOT required for the [IKEv2](ikev2-howto.md) and [IPsec/XAuth](clients-xauth.md) modes.

To fix this error, a [one-time registry change](https://documentation.meraki.com/MX-Z/Client_VPN/Troubleshooting_Client_VPN#Windows_Error_809) is required because the VPN server and/or client is behind NAT (e.g. home router). Download and import the `.reg` file below, or run the following from an [elevated command prompt](http://www.winhelponline.com/blog/open-elevated-command-prompt-windows/). **You must reboot your PC when finished.**

- For Windows Vista, 7, 8, 10 and 11 ([download .reg file](https://github.com/hwdsl2/vpn-extras/releases/download/v1.0.0/Fix_VPN_Error_809_Windows_Vista_7_8_10_Reboot_Required.reg))

  ```console
  REG ADD HKLM\SYSTEM\CurrentControlSet\Services\PolicyAgent /v AssumeUDPEncapsulationContextOnSendRule /t REG_DWORD /d 0x2 /f
  ```

- For Windows XP ONLY ([download .reg file](https://github.com/hwdsl2/vpn-extras/releases/download/v1.0.0/Fix_VPN_Error_809_Windows_XP_ONLY_Reboot_Required.reg))

  ```console
  REG ADD HKLM\SYSTEM\CurrentControlSet\Services\IPSec /v AssumeUDPEncapsulationContextOnSendRule /t REG_DWORD /d 0x2 /f
  ```

Although uncommon, some Windows systems disable IPsec encryption, causing the connection to fail. To re-enable it, run the following command and reboot your PC.

- For Windows XP, Vista, 7, 8, 10 and 11 ([download .reg file](https://github.com/hwdsl2/vpn-extras/releases/download/v1.0.0/Fix_VPN_Error_809_Allow_IPsec_Reboot_Required.reg))

  ```console
  REG ADD HKLM\SYSTEM\CurrentControlSet\Services\RasMan\Parameters /v ProhibitIpSec /t REG_DWORD /d 0x0 /f
  ```

### Windows error 789 or 691

> Error 789: The L2TP connection attempt failed because the security layer encountered a processing error during initial negotiations with the remote computer.

> Error 691: The remote connection was denied because the user name and password combination you provided is not recognized, or the selected authentication protocol is not permitted on the remote access server.

For error 789, click [here](https://documentation.meraki.com/MX/Client_VPN/Troubleshooting_Client_VPN#Windows_Error_789) for troubleshooting information. For error 691, you may try removing and recreating the VPN connection, by following the instructions in this document. Make sure that the VPN credentials are entered correctly.

### Windows error 628 or 766

> Error 628: The connection was terminated by the remote computer before it could be completed.

> Error 766: A certificate could not be found. Connections that use the L2TP protocol over IPSec require the installation of a machine certificate, also known as a computer certificate.

To fix these errors, please follow these steps:

1. Right-click on the wireless/network icon in your system tray.
1. Select **Open Network and Sharing Center**. Or, if using Windows 10 version 1709 or newer, select **Open Network & Internet settings**, then on the page that opens, click **Network and Sharing Center**.
1. On the left, click **Change adapter settings**. Right-click on the new VPN and choose **Properties**.
1. Click the **Security** tab. Select "Layer 2 Tunneling Protocol with IPsec (L2TP/IPSec)" for **Type of VPN**.
1. Click **Allow these protocols**. Check the "Challenge Handshake Authentication Protocol (CHAP)" and "Microsoft CHAP Version 2 (MS-CHAP v2)" checkboxes.
1. Click the **Advanced settings** button.
1. Select **Use preshared key for authentication** and enter `Your VPN IPsec PSK` for the **Key**.
1. Click **OK** to close the **Advanced settings**.
1. Click **OK** to save the VPN connection details.

For reference, see [this screenshot](images/vpn-properties.png) of the VPN connection properties dialog.

### Windows 10 connecting

If using Windows 10 and the VPN is stuck on "connecting" for more than a few minutes, try these steps:

1. Right-click on the wireless/network icon in your system tray.
1. Select **Open Network & Internet settings**, then on the page that opens, click **VPN** on the left.
1. Select the new VPN entry, then click **Connect**. If prompted, enter `Your VPN Username` and `Password`, then click **OK**.

### Windows 10 upgrades

After upgrading Windows 10 version (e.g. from 1709 to 1803), you may need to re-apply the fix above for [Windows Error 809](#windows-error-809) and reboot.

### Windows DNS leaks and IPv6

Windows 8, 10 and 11 use "smart multi-homed name resolution" by default, which may cause "DNS leaks" when using the native IPsec VPN client if your DNS servers on the Internet adapter are from the local network segment. To fix, you may either [disable smart multi-homed name resolution](https://www.neowin.net/news/guide-prevent-dns-leakage-while-using-a-vpn-on-windows-10-and-windows-8/), or configure your Internet adapter to use DNS servers outside your local network (e.g. 8.8.8.8 and 8.8.4.4). When finished, [clear the DNS cache](https://support.opendns.com/hc/en-us/articles/227988627-How-to-clear-the-DNS-Cache-) and reboot your PC.

In addition, if your computer has IPv6 enabled, all IPv6 traffic (including DNS queries) will bypass the VPN. Learn how to [disable IPv6](https://support.microsoft.com/en-us/help/929852/guidance-for-configuring-ipv6-in-windows-for-advanced-users) in Windows. If you need a VPN with IPv6 support, you could instead try [OpenVPN](https://github.com/hwdsl2/openvpn-install).

### Android MTU/MSS issues

Some Android devices have MTU/MSS issues, that they are able to connect to the VPN using IPsec/XAuth ("Cisco IPsec") mode, but cannot open websites. If you encounter this problem, try running the following commands on the VPN server. If successful, you may add these commands to `/etc/rc.local` to persist after reboot.

```
iptables -t mangle -A FORWARD -m policy --pol ipsec --dir in \
  -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 \
  -j TCPMSS --set-mss 1360
iptables -t mangle -A FORWARD -m policy --pol ipsec --dir out \
  -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 \
  -j TCPMSS --set-mss 1360

echo 1 > /proc/sys/net/ipv4/ip_no_pmtu_disc
```

**Docker users:** Instead of running the commands above, you may apply this fix by adding `VPN_ANDROID_MTU_FIX=yes` to [your env file](https://github.com/hwdsl2/docker-ipsec-vpn-server#how-to-use-this-image), then re-create the Docker container.

Reference: [[1]](https://www.zeitgeist.se/2013/11/26/mtu-woes-in-ipsec-tunnels-how-to-fix/).

### Android 6 and 7

If your Android 6.x or 7.x device cannot connect, try these steps:

1. Tap the "Settings" icon next to your VPN profile. Select "Show advanced options" and scroll down to the bottom. If the option "Backward compatible mode" exists ([see screenshot](images/vpn-profile-Android.png)), enable it and reconnect the VPN. If not, try the next step.
1. Edit `/etc/ipsec.conf` on the VPN server. Find the line `sha2-truncbug` and toggle its value. i.e. Replace `sha2-truncbug=no` with `sha2-truncbug=yes`, or replace `sha2-truncbug=yes` with `sha2-truncbug=no`. Save the file and run `service ipsec restart`. Then reconnect the VPN.

**Docker users:** You may set `sha2-truncbug=yes` (default is `no`) in `/etc/ipsec.conf` by adding `VPN_SHA2_TRUNCBUG=yes` to [your env file](https://github.com/hwdsl2/docker-ipsec-vpn-server#how-to-use-this-image), then re-create the Docker container.

### macOS send traffic over VPN

OS X (macOS) users: If you can successfully connect using IPsec/L2TP mode, but your public IP does not show `Your VPN Server IP`, read the [OS X](#os-x) section above and complete these steps. Save VPN configuration and re-connect.

1. Click the **Advanced** button and make sure the **Send all traffic over VPN connection** checkbox is checked.
1. Click the **TCP/IP** tab, and make sure **Link-local only** is selected in the **Configure IPv6** section.

After trying the steps above, if your computer is still not sending traffic over the VPN, check the service order. From the main network preferences screen, select "set service order" in the cog drop down under the list of connections. Drag the VPN connection to the top.

### iOS 13+ and macOS 10.15/11+

If your device running iOS 13+, macOS 10.15 (Catalina), macOS 11 (Big Sur) or above cannot connect, try these steps: Edit `/etc/ipsec.conf` on the VPN server. Find `sha2-truncbug=yes` and replace it with `sha2-truncbug=no`. Save the file and run `service ipsec restart`. Then reconnect the VPN.

In addition, users running macOS Big Sur 11.0 should update to version 11.1 or newer, to fix some issues with VPN connections. To check your macOS version and update, refer to [this article](https://www.businessinsider.com/how-to-check-mac-os-version).

### iOS/Android sleep mode

To save battery, iOS devices (iPhone/iPad) will automatically disconnect Wi-Fi shortly after the screen turns off (sleep mode). As a result, the IPsec VPN disconnects. This behavior is [by design](https://discussions.apple.com/thread/2333948) and cannot be configured.

If you need the VPN to auto-reconnect when the device wakes up, you may connect using [IKEv2](ikev2-howto.md) mode (recommended) and enable the "VPN On Demand" feature. Alternatively, you may try [OpenVPN](https://github.com/hwdsl2/openvpn-install) instead, which [has support for options](https://openvpn.net/vpn-server-resources/faq-regarding-openvpn-connect-ios/) such as "Reconnect on Wakeup" and "Seamless Tunnel".

<a name="debian-10-kernel"></a>
Android devices will also disconnect Wi-Fi shortly after entering sleep mode, unless the option "Keep Wi-Fi on during sleep" is enabled. This option is no longer available in Android 8 (Oreo) and newer. Alternatively, you may try enabling the "Always-on VPN" option to stay connected. Learn more [here](https://support.google.com/android/answer/9089766?hl=en).

### Debian 11/10 kernel

Debian 11 or 10 users: Run `uname -r` to check your server's Linux kernel version. If it contains the word "cloud", and `/dev/ppp` is missing, then the kernel lacks `ppp` support and cannot use IPsec/L2TP mode. The VPN setup scripts try to detect this and show a warning. In this case, you may instead use [IKEv2](ikev2-howto.md) or [IPsec/XAuth](clients-xauth.md) mode to connect to the VPN.

To fix the issue with IPsec/L2TP mode, you may switch to the standard Linux kernel by installing e.g. the `linux-image-amd64` package. Then update the default kernel in GRUB and reboot your server.

### Other errors

If you encounter other errors, refer to the links below:

* http://www.tp-link.com/en/faq-1029.html
* https://documentation.meraki.com/MX-Z/Client_VPN/Troubleshooting_Client_VPN#Common_Connection_Issues   
* https://stackoverflow.com/questions/25245854/windows-8-1-gets-error-720-on-connect-vpn

### Check logs and VPN status

Commands below must be run as `root` (or using `sudo`).

First, restart services on the VPN server:

```bash
service ipsec restart
service xl2tpd restart
```

**Docker users:** Run `docker restart ipsec-vpn-server`.

Then reboot your VPN client device, and retry the connection. If still unable to connect, try removing and recreating the VPN connection. Make sure that the VPN server address and VPN credentials are entered correctly.

For servers with an external firewall (e.g. [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)), open UDP ports 500 and 4500 for the VPN.

Check the Libreswan (IPsec) and xl2tpd logs for errors:

```bash
# Ubuntu & Debian
grep pluto /var/log/auth.log
grep xl2tpd /var/log/syslog

# CentOS/RHEL, Rocky Linux, AlmaLinux, Oracle Linux & Amazon Linux 2
grep pluto /var/log/secure
grep xl2tpd /var/log/messages

# Alpine Linux
grep pluto /var/log/messages
grep xl2tpd /var/log/messages
```

Check the status of the IPsec VPN server:

```bash
ipsec status
```

Show currently established VPN connections:

```bash
ipsec trafficstatus
```

## Configure Linux VPN clients using the command line

After [setting up your own VPN server](https://github.com/hwdsl2/setup-ipsec-vpn), follow these steps to configure Linux VPN clients using the command line. Alternatively, you may connect using [IKEv2](ikev2-howto.md) mode (recommended), or [configure using the GUI](#linux). Instructions below are based on [the work of Peter Sanford](https://gist.github.com/psanford/42c550a1a6ad3cb70b13e4aaa94ddb1c). Commands must be run as `root` on your VPN client.

To set up the VPN client, first install the following packages:

```bash
# Ubuntu and Debian
apt-get update
apt-get install strongswan xl2tpd net-tools

# Fedora
yum install strongswan xl2tpd net-tools

# CentOS
yum install epel-release
yum --enablerepo=epel install strongswan xl2tpd net-tools
```

Create VPN variables (replace with actual values):

```bash
VPN_SERVER_IP='your_vpn_server_ip'
VPN_IPSEC_PSK='your_ipsec_pre_shared_key'
VPN_USER='your_vpn_username'
VPN_PASSWORD='your_vpn_password'
```

Configure strongSwan:

```bash
cat > /etc/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file

conn myvpn
  auto=add
  keyexchange=ikev1
  authby=secret
  type=transport
  left=%defaultroute
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=$VPN_SERVER_IP
  ike=aes128-sha1-modp2048
  esp=aes128-sha1
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_IPSEC_PSK"
EOF

chmod 600 /etc/ipsec.secrets

# For CentOS and Fedora ONLY
mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.old 2>/dev/null
mv /etc/strongswan/ipsec.secrets /etc/strongswan/ipsec.secrets.old 2>/dev/null
ln -s /etc/ipsec.conf /etc/strongswan/ipsec.conf
ln -s /etc/ipsec.secrets /etc/strongswan/ipsec.secrets
```

Configure xl2tpd:

```bash
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac myvpn]
lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name "$VPN_USER"
password "$VPN_PASSWORD"
EOF

chmod 600 /etc/ppp/options.l2tpd.client
```

The VPN client setup is now complete. Follow the steps below to connect.

**Note:** You must repeat all steps below every time you try to connect to the VPN.

Create xl2tpd control file:

```bash
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control
```

Restart services:

```bash
service strongswan restart

# For Ubuntu 20.04, if strongswan service not found
ipsec restart

service xl2tpd restart
```

Start the IPsec connection:

```bash
# Ubuntu and Debian
ipsec up myvpn

# CentOS and Fedora
strongswan up myvpn
```

Start the L2TP connection:

```bash
echo "c myvpn" > /var/run/xl2tpd/l2tp-control
```

Run `ifconfig` and check the output. You should now see a new interface `ppp0`.

Check your existing default route:

```bash
ip route
```

Find this line in the output: `default via X.X.X.X ...`. Write down this gateway IP for use in the two commands below.

Exclude your VPN server's public IP from the new default route (replace with actual value):

```bash
route add YOUR_VPN_SERVER_PUBLIC_IP gw X.X.X.X
```

If your VPN client is a remote server, you must also exclude your Local PC's public IP from the new default route, to prevent your SSH session from being disconnected (replace with [actual value](https://www.google.com/search?q=my+ip)):

```bash
route add YOUR_LOCAL_PC_PUBLIC_IP gw X.X.X.X
```

Add a new default route to start routing traffic via the VPN server：

```bash
route add default dev ppp0
```

The VPN connection is now complete. Verify that your traffic is being routed properly:

```bash
wget -qO- http://ipv4.icanhazip.com; echo
```

The above command should return `Your VPN Server IP`.

To stop routing traffic via the VPN server:

```bash
route del default dev ppp0
```

To disconnect:

```bash
# Ubuntu and Debian
echo "d myvpn" > /var/run/xl2tpd/l2tp-control
ipsec down myvpn

# CentOS and Fedora
echo "d myvpn" > /var/run/xl2tpd/l2tp-control
strongswan down myvpn
```

## Credits

This document was adapted from the [Streisand](https://github.com/StreisandEffect/streisand) project, maintained by Joshua Lund and contributors.

## License

Note: This license applies to this document only.

Copyright (C) 2016-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
Based on [the work of Joshua Lund](https://github.com/StreisandEffect/streisand/blob/6aa6b6b2735dd829ca8c417d72eb2768a89b6639/playbooks/roles/l2tp-ipsec/templates/instructions.md.j2) (Copyright 2014-2016)

This program is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl.html) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
