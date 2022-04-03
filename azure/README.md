# Deploy to Microsoft Azure

*Read this in other languages: [English](README.md), [简体中文](README-zh.md).*

This template will create a fully working VPN server on the Microsoft Azure Cloud ([pricing details](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/)).

Customizable with the following options:

 - Username for VPN **and** SSH
 - Password for VPN **and** SSH
 - IPsec Pre-Shared Key for VPN
 - Operating System Image (Ubuntu 20.04/18.04 or Debian 9)
 - Virtual Machine Size (Default: Standard_B1s)

**Note:** DO NOT use these special characters within values: `\ " '`

Press this button to start:

[![Deploy to Azure](../docs/images/azure-deploy-button.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhwdsl2%2Fsetup-ipsec-vpn%2Fmaster%2Fazure%2Fazuredeploy.json)

When the deployment finishes, Azure displays a notification. Next steps: [Configure VPN Clients](../README.md#next-steps).

**Note:** When connecting to the server using SSH, use the username and password you specified in the deployment template. To add or export IKEv2 clients, run `sudo ikev2.sh`. If somehow you still cannot SSH into the VM after running the CLI command `ssh azureuser@YOUR-VM-PUBLIC-IP` and entering the correct login credentials, see [Troubleshoot SSH connections to an Azure Linux VM that fails, errors out, or is refused](https://docs.microsoft.com/en-us/troubleshoot/azure/virtual-machines/troubleshoot-ssh-connection) and/or [Can’t SSH to Azure Linux VM because permissions are too open](https://docs.microsoft.com/en-us/troubleshoot/azure/virtual-machines/troubleshoot-ssh-permissions-too-open)

## Authors

Copyright (C) 2016 [Daniel Falkner](https://github.com/derdanu)   
Copyright (C) 2017-2022 [Lin Song](https://github.com/hwdsl2)

## Screenshot

![Azure Custom Deployment](custom_deployment_screenshot.png)
