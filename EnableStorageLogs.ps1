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
$logAnalyticsWorkspaceId = "<LAW ID>"
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
$Counter = 1000
$Skip = 0
$QueryTemp = $null
$Query = @()

$CountQuery = 'resources 
            | where type =~ "Microsoft.Storage/storageAccounts" 
            | extend properties = parse_json(properties)
            | extend tlsVersion = properties.minimumTlsVersion
            | where isnotempty(tlsVersion) and tlsVersion !contains "2"
            | count'
$QueryString = 'resources 
            | where type =~ "Microsoft.Storage/storageAccounts" 
            | extend properties = parse_json(properties)
            | extend tlsVersion = properties.minimumTlsVersion
            | where isnotempty(tlsVersion) and tlsVersion !contains "2"
            | sort by subscriptionId asc'

$TotalAZGraph = Search-AzGraph -Query $CountQuery -UseTenantScope
$TotalAZGraph = $TotalAZGraph | Select-Object -ExpandProperty Count

while ($Skip -lt $TotalAZGraph) {
    if ($skip -eq 0) {
        $QueryTemp = Search-AzGraph -Query $QueryString -first $Counter -UseTenantScope
    }
    else {
        $QueryTemp = Search-AzGraph -Query $QueryString -first $Counter -Skip $Skip -UseTenantScope
    }
    $Query += $QueryTemp
    $Skip += 1000
}
$Query = $Query | Sort-Object -Property subscriptionId

foreach ($StgAcct in $Query)
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

    # Enable diagnostic settings for logs
    $storageAccountName = $storageAccount.StorageAccountName
    $resourceId = $storageAccount.Id

    $Ids = @($resourceId + "/blobServices/default"
            $resourceId + "/fileServices/default"
            $resourceId + "/queueServices/default"
            $resourceId + "/tableServices/default"
    )
    $Ids | ForEach-Object {
        $log = @()
        $DiagSetting = Get-AzDiagnosticSetting -ResourceId $_
        $categories = Get-AzDiagnosticSettingCategory -ResourceId $_
        if ($DiagSetting.Name -notlike $DiagnosticSettingsName)
        {
            foreach ($category in $categories) {
                if ($category.CategoryType -eq "Logs")
                {
                    $log += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category $category.Name -RetentionPolicyEnabled $true
                } 
            }
            New-AzDiagnosticSetting -Name $DiagnosticSettingsName -ResourceId $_ -WorkspaceId $logAnalyticsWorkspaceId -Log $log
            Write-Output "Enabled logs for storage account: $storageAccountName and being stored in Log Analytics workspace: $LAWName"
        }
    }
}
