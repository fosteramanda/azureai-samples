// Creates an Azure AI resource with proxied endpoints for the Azure AI services provider

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('AI hub name')
param aiHubName string

@description('AI hub display name')
param aiHubFriendlyName string = aiHubName

@description('AI hub description')
param aiHubDescription string

@description('Resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

@description('Resource ID of the AI Services resource')
param aiServicesId string

@description('Resource ID of the AI Services endpoint')
param aiServicesTarget string

@description('Name AI Services resource')
param aiServicesName string

@description('Resource Group name of the AI Services resource')
param aiServiceAccountResourceGroupName string

@description('Subscription ID of the AI Services resource')
param aiServiceAccountSubscriptionId string

@description('AI Service Account kind: either OpenAI or AIServices')
param aiServiceKind string 

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Resource ID of the Bing Search resource')
param bingSearchName string

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aiServicesName
  scope: resourceGroup(aiServiceAccountSubscriptionId, aiServiceAccountResourceGroupName)
}

#disable-next-line BCP081
resource bingSearch 'Microsoft.Bing/accounts@2020-06-10' existing = {
  name: bingSearchName
  scope: resourceGroup()
}

var bingConnectionName = '${aiHubName}-connection-Bing'


resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // organization
    friendlyName: aiHubFriendlyName
    description: aiHubDescription

    // dependent resources
    keyVault: keyVaultId
    storageAccount: storageAccountId
    systemDatastoresAuthMode: 'identity'
  }
  kind: 'hub'

    resource aiServicesConnection 'connections@2024-10-01-preview' = {
    name: '${aiHubName}-connection-AIServices'
    properties: {
      category: aiServiceKind
      target: aiServicesTarget
      authType: 'AAD'
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
        Location: aiServices.location
      }
    }
  }

  resource hub_connection_bing 'connections@2024-07-01-preview' = {
    name: bingConnectionName
    properties: {
      category: 'ApiKey'
      target: 'https://api.bing.microsoft.com/'
      authType: 'ApiKey'
      isSharedToAll: true
      credentials: {
        key: '${listKeys(bingSearch.id, '2020-06-10').key1}'
      }
      metadata: {
        ApiType: 'Azure'
        ResourceId: bingSearch.id
        location: bingSearch.location
      }
    }
  }

}
output aiHubID string = aiHub.id
