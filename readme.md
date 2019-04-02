# Demo

This is my demo repository to work on the following scenario:

>Using ARM templates and best practices, create the following:
>
>* An Azure Datalake Gen 2 storage account.
>* A key vault with a secret
>* A virtual network
>* A web app that can access both the datalake storage and the key vault secret
>* A load balancer that sits between the web app and the internet
>* Use tags to group the resources.
>
>Take note of your assumptions, and explain the choices you made
>
>Key aspect we would like to see are:
>
>1. Reusability
>2. Flexibility
>3. Robustness

Assumption: Since the scenario mentions a Load balancer and virtual network, I assume we are **required** to run the web app in a VM / VMSS instead of Azure Web App (considering the requirements for a web facing application with no reliance on other network attached resources, I normally would prefer to deploy the application to an Azure Web App / Functions App over VMs but this would mean no load balance nor vnet would be required).

## Notes

### An Azure Datalake Gen 2 storage account

First lookup [Datalake Gen 2 Storage documentation](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction?toc=%2fazure%2fstorage%2fblobs%2ftoc.json)
Most notably: `A fundamental part of Data Lake Storage Gen2 is the addition of a hierarchical namespace to Blob storage.`
Look at [schema](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2018-11-01/storageaccounts#storageaccountpropertiescreateparameters-object). Property to set is `isHnsEnabled`.

Created [simple template](/Templates/datalake-storage.json)

```powershell
New-AzResourceGroup -Name demo -Location 'West Europe' -Tag @{CostCenter='blackhole'}
New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\Storage\datalake-storage.json -storageAccountName bgdemostordatalake
```

Time taken, 30 mins.

### Add initial QA tests

Azure ARM templates work well when written consistently. To ensure a baseline, I'm adding a bunch of Pester tests to help ensure the consistency. I've setup CI with Azure DevOps which will run these tests every time something is committed to master (normally this would happen at PR time, but since this a demo project, I've not protected master).

[![Build Status](https://dev.azure.com/bgelens/DemoProject/_apis/build/status/bgelens.Demo?branchName=master)](https://dev.azure.com/bgelens/DemoProject/_build/latest?definitionId=3&branchName=master)

The tests can be run locally by running ```Invoke-Pester``` in PowerShell. It is also possible to setup a pre-commit and / or pre-push hook to have the test run automatically on the client side. I've included a sample pre-push hook which can be installed by running:

```powershell
New-Item -Path ./.git/hooks -Name pre-push -ItemType HardLink -Value ./hooks/pre-push -Force
```

Time taken, 1 hour.

### A key vault with a secret

Look at schema and decide to create 3 templates for optimal composability:

* [vault](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/2018-02-14/vaults)
* [accesspolicies](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/2018-02-14/vaults/accesspolicies)
* [secrets](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/2018-02-14/vaults/secrets)

```powershell
$kvDeploy = New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\KeyVault\keyvault.json -keyvaultName bgdemokv -enabledForDeployment $true -enabledForTemplateDeployment $true

New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\KeyVault\keyvault-secret.json -keyvaultResourceId $kvDeploy.Outputs['keyvaultResourceId'].value -secretName bgsecret -secretValue (ConvertTo-SecureString 'Super$3cret!' -AsPlainText -Force)
```

Time taken, 30 mins.

### A virtual network

```powershell
$vnetDeploy = New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\Network\virtualnetwork.json -namePrefix bg -vNetAddressPrefixes '192.168.1.0/24' -subnets @(
  @{
    subnetName = 'default'
    addressPrefix = '192.168.1.0/24'
  }
)
```

### VM

```powershell
$subnetResourceId = $vnetDeploy.Outputs['vNetResourceId'].value + '/subnets/default'

$vmDeploy = New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\Compute\virtualmachine-win.json -vmName bgvm01 -vmSize Standard_DS1_v2 -osSku '2019-Datacenter' -subnetResourceId $subnetResourceId -adminUsername ben -adminPassword (ConvertTo-SecureString 'SecureP@$word!01' -AsPlainText -Force)
```

### keyvault policy

```powershell
New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\KeyVault\keyvault-policy.json -keyVaultName 'bgdemokv' -objectId $vmDeploy.Outputs['managedIdentityPrincipalId'].value -permissions @{
  secrets = @(
    'get',
    'list'
  )
}
```
