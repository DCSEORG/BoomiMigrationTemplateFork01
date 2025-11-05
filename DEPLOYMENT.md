# Boomi to Azure Logic App Migration

This repository contains the Azure Logic App solution that migrates the Boomi integration process for syncing customer data from SQL Server to Oracle Database.

## 📋 Solution Overview

The solution implements a serverless Azure Logic App (Consumption plan) that:
- **Triggers** when new rows are added to a SQL Server database table
- **Transforms** the data according to the Boomi mapping rules
- **Inserts** the transformed data into Oracle Database

### Data Transformation

The Logic App replicates the Boomi data mapping:

| Source (SQL Server) | Target (Oracle) | Description |
|---------------------|-----------------|-------------|
| CustomerId          | id              | Customer identifier |
| Name                | fullName        | Customer full name |
| Email               | emailAddress    | Customer email |

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription** with sufficient permissions
3. **SQL Server** with Customer table
4. **Oracle Database** with target table

### One-Command Deployment

1. Configure your connection details in `infrastructure/parameters.json`:
   ```bash
   cp infrastructure/parameters.json infrastructure/parameters.json.backup
   # Edit infrastructure/parameters.json with your actual values
   ```

2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

That's it! The script handles everything:
- Azure login verification
- Resource group creation
- Bicep template validation
- Infrastructure deployment
- Output summary with next steps

## 📁 Repository Structure

```
.
├── Boomi(.DAR)/              # Original Boomi integration files
│   ├── Components/           # Boomi components (connections, operations, maps)
│   ├── Process/              # Boomi process definitions
│   └── EnvironmentExtensions/
├── infrastructure/           # Azure infrastructure as code
│   ├── main.bicep           # Main Bicep template
│   ├── parameters.json      # Configuration parameters
│   ├── workflow-definition.json  # Logic App workflow
│   └── README.md            # Detailed infrastructure docs
├── deploy.sh                # One-command deployment script
├── .env.example            # Example environment variables
└── DEPLOYMENT.md           # This file
```

## 🔧 Configuration

### Required Parameters

Edit `infrastructure/parameters.json`:

```json
{
  "sqlConnectionString": {
    "value": "your-server.database.windows.net"
  },
  "sqlUsername": {
    "value": "your-username"
  },
  "sqlPassword": {
    "value": "your-password"
  },
  "oracleConnectionString": {
    "value": "oracle-server:1521/service-name"
  },
  "oracleUsername": {
    "value": "oracle-user"
  },
  "oraclePassword": {
    "value": "oracle-password"
  }
}
```

### Optional Configuration

You can customize deployment settings by exporting environment variables:

```bash
export RESOURCE_GROUP_NAME="my-custom-rg"
export LOCATION="westus2"
./deploy.sh
```

## 📊 Post-Deployment

After deployment, authorize the API connections:

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Go to your Resource Group
3. Authorize SQL and Oracle connections
4. Enable the Logic App

Detailed instructions are provided in the deployment script output.

## 🔍 Monitoring

View Logic App runs:
```bash
az logic workflow list-runs \
    --resource-group rg-customer-sync \
    --name logic-customer-sync \
    --output table
```

Check specific run:
```bash
az logic workflow show-run \
    --resource-group rg-customer-sync \
    --name logic-customer-sync \
    --run-name <run-id>
```

## 🧪 Testing

### Prerequisites
Ensure your SQL Server has test data:

```sql
INSERT INTO dbo.Customer (CustomerId, Name, Email, Active)
VALUES (1, 'John Doe', 'john.doe@example.com', 1);
```

### Verify Data Flow

1. Insert a new record in SQL Server
2. Wait for polling interval (default: 60 seconds)
3. Check Logic App run history in Azure Portal
4. Verify data in Oracle Database:
   ```sql
   SELECT * FROM CUSTOMERS WHERE id = 1;
   ```

## 🛠️ Troubleshooting

### Common Issues

**Problem**: API connections not authorized
- **Solution**: Follow post-deployment steps to authorize connections

**Problem**: Logic App not triggering
- **Solution**: Check SQL table name and schema match the configuration

**Problem**: Data not in Oracle
- **Solution**: Review Logic App run history for error details

For more troubleshooting tips, see `infrastructure/README.md`.

## 💰 Cost Estimation

The Logic App Consumption plan charges based on:
- Action executions
- Connector operations

Estimated monthly cost for low-volume usage (assuming 1000 new records/month):
- Logic App actions: ~$0.08
- SQL connector: ~$0.10
- Oracle connector: ~$0.10
- **Total**: ~$0.28/month

For detailed pricing: [Azure Logic Apps Pricing](https://azure.microsoft.com/en-us/pricing/details/logic-apps/)

## 🧹 Cleanup

Remove all deployed resources:

```bash
az group delete --name rg-customer-sync --yes --no-wait
```

## 📚 Additional Resources

- [Azure Logic Apps Documentation](https://docs.microsoft.com/en-us/azure/logic-apps/)
- [SQL Server Connector Best Practices](https://docs.microsoft.com/en-us/azure/connectors/connectors-create-api-sqlazure?tabs=consumption)
- [Oracle Database Connector Documentation](https://docs.microsoft.com/en-us/azure/connectors/connectors-create-api-oracledatabase)
- [Bicep Language Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## 🤝 Contributing

This is a migration template. Customize according to your needs:
- Adjust polling intervals
- Add error handling
- Implement retry policies
- Add logging and monitoring

## 📝 License

This project is provided as-is for migration purposes.
