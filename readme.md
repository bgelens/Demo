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

## Notes

### An Azure Datalake Gen 2 storage account

First lookup [Datalake Gen 2 Storage documentation](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction?toc=%2fazure%2fstorage%2fblobs%2ftoc.json)
Most notably: `A fundamental part of Data Lake Storage Gen2 is the addition of a hierarchical namespace to Blob storage.`
Look at [schema](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2018-11-01/storageaccounts#storageaccountpropertiescreateparameters-object). Property to set is `isHnsEnabled`.

Created [simple template](/Templates/datalake-storage.json)

```powershell
New-AzResourceGroup -Name demo -Location 'West Europe' -Tag @{CostCenter='blackhole'}
New-AzResourceGroupDeployment -ResourceGroupName demo -TemplateFile .\Templates\datalake-storage.json -storageAccountName bgdemostordatalake
```

Time taken, 30 mins.

### Add initial QA tests

Azure ARM templates work well when written consistently. To ensure a baseline, I'm adding a bunch of Pester tests to help ensure the consistency. I've setup CI with Azure DevOps which will run these tests every time something is committed to master (normally this would happen at PR time, but since this a demo project, I've not protected master).

[![Build Status](https://dev.azure.com/bgelens/DemoProject/_apis/build/status/bgelens.Demo?branchName=master)](https://dev.azure.com/bgelens/DemoProject/_build/latest?definitionId=3&branchName=master)

Time taken, 1 hour.
