# Boomi to Azure Logic App Migration Template

This repository contains a complete migration solution from Boomi to Azure Logic Apps for customer data synchronization.

## 🎯 What's Included

- **Boomi Integration Files** (`Boomi(.DAR)/`) - Original Boomi process and components
- **Azure Logic App Infrastructure** (`infrastructure/`) - Bicep templates for Azure deployment
- **One-Command Deployment** (`deploy.sh`) - Automated deployment script
- **Comprehensive Documentation** - Setup and troubleshooting guides

## 🚀 Quick Start

Deploy the Logic App to Azure in one command:

```bash
./deploy.sh
```

For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## 📖 Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide and usage
- [infrastructure/README.md](infrastructure/README.md) - Technical infrastructure details

## 🔄 What This Does

The solution migrates the Boomi integration to Azure Logic Apps:

1. **Monitors** SQL Server for new customer records
2. **Transforms** data (CustomerId→id, Name→fullName, Email→emailAddress)
3. **Inserts** into Oracle Database

## 📋 Prerequisites

- Azure CLI installed
- Azure subscription
- SQL Server with Customer table
- Oracle Database with target table

## 💡 Architecture

- **Azure Logic App (Consumption)** - Serverless, pay-per-use
- **SQL Server Connector** - Triggers on new rows
- **Oracle Database Connector** - Inserts transformed data
- **Built-in Data Mapping** - Replicates Boomi transformations

## 📞 Support

See [DEPLOYMENT.md](DEPLOYMENT.md) for troubleshooting and detailed documentation.
