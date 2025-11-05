# Quick Reference Guide

## One-Command Deployment

```bash
./deploy.sh
```

## Pre-Deployment Checklist

- [ ] Azure CLI installed (`az --version`)
- [ ] Logged into Azure (`az login`)
- [ ] Updated `infrastructure/parameters.json` with:
  - [ ] SQL Server connection details
  - [ ] SQL username and password
  - [ ] Oracle connection details
  - [ ] Oracle username and password
  - [ ] Table names (if different from defaults)

## Configuration Files

### infrastructure/parameters.json
Update these values before deployment:
```json
{
  "sqlConnectionString": {"value": "your-server.database.windows.net"},
  "sqlUsername": {"value": "your-username"},
  "sqlPassword": {"value": "your-password"},
  "oracleConnectionString": {"value": "oracle:1521/service"},
  "oracleUsername": {"value": "oracle-user"},
  "oraclePassword": {"value": "oracle-pass"}
}
```

## Post-Deployment

1. Go to Azure Portal
2. Find your Logic App: `logic-customer-sync`
3. Authorize API connections:
   - SQL Server connection
   - Oracle Database connection
4. Test with a new SQL record

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
| Connection not authorized | Go to Azure Portal → API Connections → Authorize |
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
