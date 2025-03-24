// Assigns the necessary roles to the AI project

@description('Name of the AI Search resource')
param cosmosAccountName string

@description('Principal ID of the AI project')
param aiProjectPrincipalId string

@description('Resource ID of the AI project')
param aiProjectId string

param projectWorkspaceId string

var userThreadName = '${projectWorkspaceId}-thread-messaage-store'
var systemThreadName = '${projectWorkspaceId}-system-thread-messaage-store'


#disable-next-line BCP081
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2025-01-01-preview' existing = {
  name: cosmosAccountName
  scope: resourceGroup()
}

// Reference existing database
#disable-next-line BCP081
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-01-01-preview' existing = {
  parent: cosmosAccount
  name: 'enterprise_memory'
}

#disable-next-line BCP081
resource conatinerUserMessageStore 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-01-01-preview' existing = {
  parent: database
  name: '${projectWorkspaceId}-thread-message-store'
}

#disable-next-line BCP081
resource containerSystemMessageStore 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-01-01-preview' existing = {
  parent: database
  name: '${projectWorkspaceId}-system-thread-message-store'
}


var roleDefinitionId = resourceId(
  'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', 
  cosmosAccountName, 
  '00000000-0000-0000-0000-000000000002'
)

var scopeSystemContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/${database.name}/colls/${systemThreadName}'
var scopeUserContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/${database.name}/colls/${userThreadName}'

resource containerRoleAssignmentUserContainer 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(aiProjectId, conatinerUserMessageStore.id, roleDefinitionId)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeUserContainer
  }
}

resource containerRoleAssignmentSystemContainer 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(aiProjectId, containerSystemMessageStore.id, roleDefinitionId)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeSystemContainer
  }
}
