# EnableTransactionLogs

# Prerequisites
Mandatory Modules:<br />
  - az.monitor
  - az.resourcegraph

# Configuring the code
- Before executing the code, it's required to setup the Log Analytics Workspace ID in the code:<br />
  $logAnalyticsWorkspaceId = "LAW Workspace ID"
- This information can be found from the Azure portal:<br />
  - ![image](https://github.com/user-attachments/assets/9fb85f1a-9408-4dde-82c7-aab9bf3c6111)
    <br />
  - ![image](https://github.com/user-attachments/assets/fd9947de-86c7-4d8f-bdd6-dc283734cfc2)

- Replace "LAW Workspace ID" with the Workspace ID from the Azure portal<br />
  - ![image](https://github.com/user-attachments/assets/fc54cdc4-89b4-42ed-bd2c-88a652be29b5)

# The code can be executed simply starting the execution:
- .\EnableTransactionLogs.ps1
