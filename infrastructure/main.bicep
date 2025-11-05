// Main Bicep file for Logic App (Consumption) deployment
// This creates a Logic App that syncs customer data from SQL Server to Oracle Database

@description('The location for all resources')
param location string = resourceGroup().location

@description('The name of the Logic App')
param logicAppName string = 'logic-customer-sync'

@description('SQL Server connection string')
@secure()
param sqlConnectionString string

@description('SQL Database name')
param sqlDatabaseName string

@description('SQL Server username')
param sqlUsername string

@description('SQL Server password')
@secure()
param sqlPassword string

@description('Oracle Server connection string')
@secure()
param oracleConnectionString string

@description('Oracle username')
param oracleUsername string

@description('Oracle password')
@secure()
param oraclePassword string

@description('SQL table name to monitor')
param sqlTableName string = 'dbo.Customer'

@description('Oracle table name to insert into')
param oracleTableName string = 'CUSTOMERS'

@description('Polling interval in seconds')
param pollingIntervalInSeconds int = 60

// SQL Server API Connection
resource sqlConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'sql-connection'
  location: location
  properties: {
    displayName: 'SQL Server Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
    }
    parameterValues: {
      server: sqlConnectionString
      database: sqlDatabaseName
      username: sqlUsername
      password: sqlPassword
    }
  }
}

// Oracle Database API Connection
resource oracleConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'oracle-connection'
  location: location
  properties: {
    displayName: 'Oracle Database Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'oracle')
    }
    parameterValues: {
      server: oracleConnectionString
      username: oracleUsername
      password: oraclePassword
    }
  }
}

// Logic App (Consumption)
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_item_is_created': {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'default\'))},@{encodeURIComponent(encodeURIComponent(\'default\'))}/tables/@{encodeURIComponent(encodeURIComponent(\'${sqlTableName}\'))}/onnewitems'
            queries: {
              incomingBlobMetadata: 'None'
            }
          }
          recurrence: {
            frequency: 'Second'
            interval: pollingIntervalInSeconds
          }
          splitOn: '@triggerBody()?[\'value\']'
        }
      }
      actions: {
        'Transform_Data': {
          type: 'Compose'
          inputs: {
            id: '@triggerBody()?[\'CustomerId\']'
            fullName: '@triggerBody()?[\'Name\']'
            emailAddress: '@triggerBody()?[\'Email\']'
          }
          runAfter: {}
        }
        'Insert_into_Oracle': {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'oracle\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'default\'))}/tables/@{encodeURIComponent(encodeURIComponent(\'${oracleTableName}\'))}/items'
            body: '@outputs(\'Transform_Data\')'
          }
          runAfter: {
            Transform_Data: [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          sql: {
            connectionId: sqlConnection.id
            connectionName: sqlConnection.name
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'sql')
          }
          oracle: {
            connectionId: oracleConnection.id
            connectionName: oracleConnection.name
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'oracle')
          }
        }
      }
    }
  }
}

// Outputs
output logicAppId string = logicApp.id
output logicAppName string = logicApp.name
output sqlConnectionId string = sqlConnection.id
output oracleConnectionId string = oracleConnection.id
