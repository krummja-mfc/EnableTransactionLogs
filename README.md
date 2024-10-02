# EnableTransactionLogs

# Prerequisites
Mandatory Modules:<br />
  - az.monitor
  - az.resourcegraph

# Configuring the code
- Before executing the code, it's required to setup the Log Analytics Workspace ID in the code:<br />
  $logAnalyticsWorkspaceId = "<LAW Workspace ID>"
- This information can be found from the Azure portal:<br />
  - ![image](https://github.com/user-attachments/assets/32926310-55ca-442c-9fd1-114e50982aca)
- Replace "<LAW Workspace ID>" with the Workspace ID from the Azure portal<br />

# The code can be executed simply starting the execution:
- .\EnableTransactionLogs.ps1
