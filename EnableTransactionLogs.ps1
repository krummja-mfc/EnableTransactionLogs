<#
MIT License
Copyright 2024 Guil Lima

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

# Variables
$LAWName = "azurelimits"
$logAnalyticsWorkspaceId = "<LAW Workspace ID>"
$DiagnosticSettingsName = "TLSTransactionLogs"
$Context = $null
$SubscriptionId = $null

# Enable Modules
Import-Module az.monitor
import-module az.resourcegraph

# Connecting to Azure
try {
    Connect-AzAccount
} catch
{
    Write-Output "Error Connecting to Azure Portal"
    exit 0
}


# List storage accounts 
$Query = 'resources 
            | where type =~ "Microsoft.Storage/storageAccounts" 
            | extend properties = parse_json(properties)
            | extend tlsVersion = properties.minimumTlsVersion
            | where isnotempty(tlsVersion) and tlsVersion !contains "2"
            | sort by subscriptionId asc'
$kqlQuery = Search-AzGraph -Query $Query -UseTenantScope

# Setting up Log Configuration for Transaction Logs
$metric = New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category "Transaction" -RetentionPolicyEnabled $true

foreach ($StgAcct in $kqlQuery)
{
    $SubscriptionId = $StgAcct.subscriptionId
    if ($Context -ne $SubscriptionId)
    {
        # Set the subscription context
        $null = Set-AzContext -Subscription $StgAcct.subscriptionId
        $Context = $StgAcct.subscriptionId
    }

    # Get storage accounts information
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $StgAcct.resourcegroup -Name $StgAcct.name

    # Enable diagnostic settings for transaction logs
    $storageAccountName = $storageAccount.StorageAccountName
    $resourceId = $storageAccount.Id

    New-AzDiagnosticSetting -Name $DiagnosticSettingsName -ResourceId $resourceId -WorkspaceId $logAnalyticsWorkspaceId -Metric $metric

    Write-Output "Enabled transaction logs for storage account: $storageAccountName and being stored in Log Analytics workspace: $LAWName"
}
