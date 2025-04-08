

param account_name string = 'aiServices${substring(uniqueString(utcNow()), 0,4)}'
param project_name string = 'project'
param description string = 'some description'
param display_name string = 'project_display_name'
param location string = 'westus2'

param modelName string = 'gpt-4o'
param modelFormat string = 'OpenAI'
param modelVersion string = '2024-05-13'
param modelSkuName string = 'GlobalStandard'
param modelCapacity int = 50

#disable-next-line BCP081
resource account_name_resource 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: account_name
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: account_name
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

/*
  Step 2: Deploy gpt-4o model
  
  - Agents will use the build-in model deployments
*/ 
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01'= {
  parent: account_name_resource
  name: modelName
  sku : {
    capacity: modelCapacity
    name: modelSkuName
  }
  properties: {
    model:{
      name: modelName
      format: modelFormat
      version: modelVersion
    }
  }
}

#disable-next-line BCP081
resource account_name_project_name 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: account_name_resource
  name: '${project_name}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: description
    displayName: display_name
  }
}
