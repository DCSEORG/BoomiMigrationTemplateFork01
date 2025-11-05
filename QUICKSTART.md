# Quick Reference Guide

## One-Command Deployment

```bash
./deploy.sh
```

## Pre-Deployment Checklist

- [ ] Azure CLI installed (`az --version`)
- [ ] Logged into Azure (`az login`)
- [ ] SQL Server has Azure AD authentication enabled
- [ ] Updated `infrastructure/parameters.json` with:
  - [ ] SQL Server connection details (server and database name)
  - [ ] Oracle connection details
  - [ ] Oracle username and password
  - [ ] Table names (if different from defaults)

## Configuration Files

### infrastructure/parameters.json
Update these values before deployment:
```json
{
  "sqlConnectionString": {"value": "your-server.database.windows.net"},
  "sqlDatabaseName": {"value": "your-database-name"},
  "oracleConnectionString": {"value": "oracle:1521/service"},
  "oracleUsername": {"value": "oracle-user"},
  "oraclePassword": {"value": "oracle-pass"}
}
```

**Note**: SQL authentication now uses Azure AD (Entra ID) with Managed Identity. SQL username and password are no longer required.

## Post-Deployment

1. **Grant SQL Database Access**: Connect to your SQL Database as an Azure AD admin and run:
   ```sql
   CREATE USER [logic-customer-sync] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [logic-customer-sync];
   ALTER ROLE db_datawriter ADD MEMBER [logic-customer-sync];
   ```

2. **Ensure SQL Server Configuration**:
   - Azure AD authentication is enabled
   - Firewall allows Azure services

3. **Authorize Oracle Connection**:
   - Go to Azure Portal → Your Resource Group
   - Find and authorize the Oracle API connection

4. **Test**: Insert a new record in SQL and verify it appears in Oracle

## Testing

Insert test data:
```sql
INSERT INTO dbo.Customer (CustomerId, Name, Email, Active)
VALUES (999, 'Test User', 'test@example.com', 1);
```

Check Oracle:
```sql
SELECT * FROM CUSTOMERS WHERE id = 999;
```

## Monitoring

```bash
# List recent runs
az logic workflow list-runs \
  --resource-group rg-customer-sync \
  --name logic-customer-sync \
  --output table

# View specific run
az logic workflow show-run \
  --resource-group rg-customer-sync \
  --name logic-customer-sync \
  --run-name <RUN_ID>
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Logic App cannot connect to SQL | Ensure Azure AD auth is enabled on SQL Server and managed identity has database access |
| "Login failed" error | Run SQL grant commands from Post-Deployment section |
| Oracle connection not authorized | Go to Azure Portal → API Connections → Authorize |
| Logic App not triggering | Check SQL table name in parameters.json |
| Data not in Oracle | Review Logic App run history for errors |
| Deployment fails | Verify Azure CLI login and subscription |

## Custom Configuration

Set environment variables before running deploy.sh:
```bash
export RESOURCE_GROUP_NAME="my-rg"
export LOCATION="westus2"
./deploy.sh
```

## Cleanup

```bash
az group delete --name rg-customer-sync --yes
```

## Support

For detailed documentation:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete guide
- [infrastructure/README.md](infrastructure/README.md) - Technical details

## SQL Server Table Schema

```sql
CREATE TABLE dbo.Customer (
    CustomerId INT PRIMARY KEY,
    Name NVARCHAR(255),
    Email NVARCHAR(255),
    Active BIT
);
```

## Oracle Table Schema

```sql
CREATE TABLE CUSTOMERS (
    id NUMBER PRIMARY KEY,
    fullName VARCHAR2(255),
    emailAddress VARCHAR2(255)
);
```

## Field Mapping

| SQL Server | Oracle | Type |
|------------|--------|------|
| CustomerId | id | Integer |
| Name | fullName | String |
| Email | emailAddress | String |
