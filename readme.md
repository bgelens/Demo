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
