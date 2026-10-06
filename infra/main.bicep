// Infraestrutura do TechStore Cloud como codigo (Bicep)
// Cria monitoramento, armazenamento, cofre de segredos e regras de rede
// Uso: az deployment group create -g <grupo> -f main.bicep -p ipAdmin=<ip>

@description('Regiao dos recursos')
param location string = resourceGroup().location

@description('Prefixo dos nomes')
param prefix string = 'techstore'

@description('IP autorizado para SSH')
param ipAdmin string

@description('Sufixo para nomes globais unicos')
param sufixo string = uniqueString(resourceGroup().id)

var tags = {
  projeto: 'TechStoreCloud'
  gerenciadoPor: 'bicep'
}

resource log 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${prefix}-iac'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${prefix}-iac'
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: log.id
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${prefix}${sufixo}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: tags
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    accessTier: 'Hot'
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${prefix}-${take(sufixo, 6)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-${prefix}-iac'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: ipAdmin
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'Porta_80_443'
        properties: {
          priority: 320
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
    ]
  }
}

output storageAccount string = sa.name
output keyVault string = kv.name
output workspace string = log.name
