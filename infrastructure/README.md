# Azure Logic App - Customer Sync (Consumption Plan)

This solution migrates the Boomi integration process to Azure Logic Apps, providing a serverless, consumption-based workflow for syncing customer data from SQL Server to Oracle Database.

## Overview

This Logic App implements the same data flow as the Boomi process:

1. **Trigger**: Monitors SQL Server table for new customer records (using Azure AD authentication)
2. **Transform**: Maps SQL Server fields to Oracle format
   - `CustomerId` → `id`
   - `Name` → `fullName`
   - `Email` → `emailAddress`
3. **Action**: Inserts transformed data into Oracle Database

### Security

The Logic App uses a **system-assigned managed identity** to authenticate with SQL Server via Azure AD (Entra ID). This eliminates the need to manage SQL credentials and provides enhanced security through Azure's identity platform.

## Architecture

The solution includes:
- **Azure Logic App (Consumption)**: Serverless workflow orchestration
- **System-Assigned Managed Identity**: Secure Azure AD authentication for SQL Server
- **SQL Server API Connection**: Connects to Azure SQL or SQL Server using Azure AD
- **Oracle Database API Connection**: Connects to Oracle Database
- **Bicep Templates**: Infrastructure as Code for deployment

## Prerequisites

1. **Azure CLI** installed and configured
   - Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
2. **Azure Subscription** with appropriate permissions
3. **SQL Server** with Azure AD authentication enabled and the Customer table:
   ```sql
   CREATE TABLE dbo.Customer (
       CustomerId INT PRIMARY KEY,
       Name NVARCHAR(255),
       Email NVARCHAR(255),
       Active BIT
   );
   ```
4. **Oracle Database** with the target table:
   ```sql
   CREATE TABLE CUSTOMERS (
       id NUMBER PRIMARY KEY,
       fullName VARCHAR2(255),
       emailAddress VARCHAR2(255)
   );
   ```

## Configuration

1. Edit `infrastructure/parameters.json` with your connection details:

```json
{
  "sqlConnectionString": {
    "value": "your-server.database.windows.net"
  },
  "sqlDatabaseName": {
    "value": "your-database-name"
  },
  "oracleConnectionString": {
    "value": "your-oracle-server:1521/your-service-name"
  },
  "oracleUsername": {
    "value": "your-oracle-username"
  },
  "oraclePassword": {
    "value": "your-oracle-password"
  }
}
```

**Note**: SQL authentication now uses Azure AD (Entra ID) via Managed Identity, so SQL username and password are not required.

2. (Optional) Adjust environment variables in `deploy.sh`:
   - `RESOURCE_GROUP_NAME`: Azure resource group name (default: `rg-customer-sync`)
   - `LOCATION`: Azure region (default: `eastus`)

## Deployment

Deploy the entire solution with a single command:

```bash
./deploy.sh
```

The script will:
1. Check Azure CLI installation and login status
2. Create the resource group if needed
3. Validate the Bicep template
4. Deploy all resources to Azure
5. Display deployment summary with Logic App details

## Post-Deployment Steps

After deployment, configure Azure AD authentication and authorize connections:

### 1. Grant SQL Database Access to Managed Identity

The Logic App uses a system-assigned managed identity to access SQL Server. Grant it database access:

```sql
-- Connect to your SQL Database as an Azure AD admin and run:
CREATE USER [logic-customer-sync] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [logic-customer-sync];
ALTER ROLE db_datawriter ADD MEMBER [logic-customer-sync];
```

**Important**: 
- Your SQL Server must have Azure AD authentication enabled
- You must connect as an Azure AD admin to run these commands
- Ensure your SQL Server firewall allows Azure services

### 2. Authorize Oracle API Connection

1. Go to the [Azure Portal](https://portal.azure.com)
2. Navigate to your Resource Group
3. Click on the Oracle API Connection (oracle-connection)
4. Click "Edit API connection"
5. Provide credentials and test the connection
6. Save the connection

Alternatively, authorize from the Logic App:
1. Open the Logic App in Azure Portal
2. Click "API connections" in the left menu
3. Authorize the Oracle connection

## Monitoring

Monitor your Logic App:

1. **Azure Portal**: View run history, metrics, and logs
2. **Azure Monitor**: Set up alerts and diagnostics
3. **Application Insights**: (Optional) Add for detailed telemetry

View recent runs:
```bash
az logic workflow list-runs \
    --resource-group rg-customer-sync \
    --name logic-customer-sync
```

## Data Transformation

The Logic App performs the following field mapping:

| SQL Server Field | Oracle Field   | Transformation |
|------------------|----------------|----------------|
| CustomerId       | id             | Direct mapping |
| Name             | fullName       | Direct mapping |
| Email            | emailAddress   | Direct mapping |

The transformation is implemented using the `Compose` action in the Logic App workflow.

## Polling Configuration

By default, the Logic App polls for new records every 60 seconds. To change this:

1. Edit `parameters.json`:
   ```json
   "pollingIntervalInSeconds": {
     "value": 30
   }
   ```
2. Redeploy using `./deploy.sh`

## Troubleshooting

### Connection Authorization Issues
- **SQL**: Ensure Azure AD authentication is enabled on SQL Server and the managed identity has been granted database access
- **Oracle**: Check credentials and network connectivity; verify firewall rules

### Logic App Not Triggering
- Verify the SQL table name is correct
- Check that the table has the required columns
- Ensure the managed identity has read permissions on the table

### Data Not Appearing in Oracle
- Check Oracle connection authorization
- Verify the Oracle table schema matches the expected format
- Review Logic App run history for error messages

### "Login failed" Errors
- The managed identity may not have database access. Run the SQL grant commands from Post-Deployment Steps
- Verify SQL Server allows Azure services in firewall settings
- Confirm Azure AD authentication is properly configured on SQL Server

## Cost Optimization

The Consumption plan charges based on:
- Number of action executions
- Connector usage

To optimize costs:
- Adjust polling interval based on your needs
- Use batch operations if processing large volumes
- Monitor usage in Azure Cost Management

## Clean Up

To remove all resources:

```bash
az group delete --name rg-customer-sync --yes --no-wait
```

## References

- [Azure Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [SQL Server Connector](https://docs.microsoft.com/en-us/connectors/sql/)
- [Oracle Database Connector](https://docs.microsoft.com/en-us/connectors/oracle/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
