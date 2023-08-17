[English](README.md) | [中文](README-zh.md)

# 使用 CloudFormation 在 Amazon EC2 上部署

使用这个模板，你可以在 Amazon Elastic Compute Cloud（Amazon EC2）上快速搭建一个 IPsec VPN 服务器。在继续之前，请参见 EC2 [定价细节](https://aws.amazon.com/cn/ec2/pricing/on-demand/)。在部署中使用 `t2.micro` 服务器实例可能符合 [AWS 免费套餐](https://aws.amazon.com/cn/free/) 的资格。

可用的自定义参数：

- Amazon EC2 实例类型
> <details><summary><strong>注：</strong> 在某些 AWS 区域中，此模版提供的某些实例类型可能不可用。（点击查看详情）
> </summary>
> 
> 比如 `m5a.large` 可能无法在 `ap-east-1` 区域部署（仅为假设）。在此情况下，你会在部署过程中遇到此错误：`The requested configuration is currently not supported. Please check the documentation for supported configurations`。新开放的 AWS 区域更容易出现此问题，因为它们提供的实例类型较少。如需了解更多关于实例可用性的信息，请参见 [https://instances.vantage.sh/](https://instances.vantage.sh/)。</details>

- VPN 服务器的操作系统（Ubuntu 22.04/20.04, Debian 10/11/12, CentOS 7, Amazon Linux 2）
- 你的 VPN 用户名
- 你的 VPN 密码
- 你的 VPN IPsec PSK（预共享密钥）

> **注：** \*不要\* 在值中使用这些字符： `\ " '`

确保使用 **AWS 账户根用户** 或者有 **管理员权限** 的 **IAM 用户** 部署此模板。

右键单击这个 [**模板链接**](https://raw.githubusercontent.com/hwdsl2/setup-ipsec-vpn/master/aws/cloudformation-template-ipsec.json)，并将它保存到你的计算机上的一个新文件。然后在 ["创建堆栈" 向导](https://console.aws.amazon.com/cloudformation/home#/stacks/new)中将其作为模板源上传。继续创建堆栈，在最后一步你需要确认（选择）此模板可以创建 IAM 资源。

<details>
<summary>
点这里查看屏幕截图
</summary>

![上传模板](images/upload-the-template.png)
![指定参数](images/specify-parameters.png)
![确认 IAM](images/confirm-iam.png)
</details>

点击下面的图标开始：

[![Launch stack](images/cloudformation-launch-stack-button.png)](https://console.aws.amazon.com/cloudformation/home#/stacks/new)

要指定一个 AWS 区域，你可以使用导航栏上你的帐户信息右侧的选择器。当你在最后一步中点击 "create stack" 之后，请等待堆栈创建和 VPN 安装完成，可能需要最多 15 分钟。一旦堆栈的部署状态变成 **"CREATE_COMPLETE"** ，你就可以连接到 VPN 服务器了。单击 **Outputs** 选项卡以查看你的 VPN 登录信息，然后继续下一步：[配置 VPN 客户端](../README-zh.md#下一步)。

> **注：** 如果你删除使用此模板部署的 CloudFormation 堆栈，在部署期间添加的密钥对将不会自动被清理。要管理你的密钥对，请转到 EC2 控制台 -> 密钥对。

## 常见问题

<details>
<summary>
如何在部署结束后提取 IKEv2 连接配置文件？
</summary>

部署结束以后，生成的 IKEv2 配置文件已经被上传到了一个预先创建好的 AWS Simple Storage Service(S3) 储存桶。下载配置文件的链接可以在 **Outputs** 页面下找到。

点击下载链接下载名为 `profiles.zip` 的压缩包文件。解压密码为**你之前配置好的 VPN 连接密码。**

值得注意的是，配置文件下载链接将会在**1天内过期**，从堆栈部署完成时算起。如果你将堆栈删除，存放配置文件的储存桶不会被删除。

关于如何在 IKEv2 模式下配置你的客户端，请参见: [IKEv2 VPN 配置和使用指南](/docs/ikev2-howto-zh.md#管理-ikev2-客户端)。

![IKEv2 配置文件](images/credentials.png)

</details>

<details>
<summary>
部署后如何通过 SSH 连接到服务器？
</summary>

你需要你的 Amazon EC2 实例的用户名和私钥，才能通过 SSH 登录到该实例。

EC2 上的每个 Linux 服务器发行版本都有它自己的默认登录用户名。新实例默认禁用密码登录，必须使用私钥或 “密钥对” 登录。

默认用户名列表：
> **参考链接：** [https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/connection-prereqs.html#connection-prereqs-private-key](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/connection-prereqs.html#connection-prereqs-private-key)

| 发行版本 | 默认登录用户名 |
| --- | --- |
| Ubuntu |  `ubuntu` |
| Debian | `admin` |
| CentOS (`CentOS 7`) | `centos` |
| Amazon Linux 2 | `ec2-user` |

此模板在部署期间为你生成一个密钥对，并且在成功创建堆栈后，其中的私钥将在 **Outputs** 选项卡下以文本形式提供。

如果要通过 SSH 访问 VPN 服务器，则需要将 **Outputs** 选项卡中的私钥保存到你的计算机上的一个新文件。

> **注：** 在保存到你的计算机之前，你可能需要修改私钥的格式，比如用换行符替换所有的空格。在保存后，需要为该私钥文件设置[适当的权限](https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/connection-prereqs.html#connection-prereqs-private-key)才能使用。

![显示密钥](images/show-key.png)

要为私钥文件设置适当的权限，请在该文件所在的目录下运行以下命令：
```bash
$ sudo chmod 400 key-file.pem
```

使用 SSH 登录到 EC2 实例的示例命令：
```bash
$ ssh -i path/to/your/key-file.pem instance-username@instance-ip-address
```
</details>

## 作者

版权所有 (C) 2020-2023 [Scott X. L.](https://github.com/scottpedia) <[wtanglef@pm.me](mailto:wtanglef@pm.me)>
