@description('The location in which the resources should be deployed.')
param Location string = 'westeurope'

param RegistryUsername string

param StorageName string
param ContainerInstanceName string

@secure()
param RegistryPassword string

var VolumeName = 'data-volume'

resource StorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: StorageName
  location: Location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

resource FileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: StorageAccount
}

resource DataShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: 'unifi-data'
  parent: FileService
}

resource ContainerInstance 'Microsoft.ContainerInstance/containerGroups@2022-09-01' = {
  name: ContainerInstanceName
  identity: {
    type: 'SystemAssigned'
  }
  location: Location
  properties: {
    containers: [
      {
        name: 'unifi-controller'
        properties: {
          image: 'linuxserver/unifi-controller:latest'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          ports: [
            {
              port: 8443
              protocol: 'TCP'
            }
            {
              port: 3478
              protocol: 'UDP'
            }
            {
              port: 10001
              protocol: 'UDP'
            }
            {
              port: 8080
              protocol: 'TCP'
            }
            {
              port: 1900
              protocol: 'UDP'
            }
            {
              port: 8843
              protocol: 'TCP'
            }
            {
              port: 8880
              protocol: 'TCP'
            }
            {
              port: 6789
              protocol: 'TCP'
            }
            {
              port: 5514
              protocol: 'UDP'
            }
          ]
          volumeMounts: [
            {
              name: VolumeName
              mountPath: '/config'
              readOnly: false 
            }
          ]
          readinessProbe: {
            httpGet: {
              port: 8443
              scheme: 'https'
              path: '/'
            }
            initialDelaySeconds: 10
            failureThreshold: 20
            periodSeconds: 10
            successThreshold: 1
          }
          livenessProbe: {
            httpGet: {
              port: 8443
              scheme: 'https'
              path: '/'
            }
            initialDelaySeconds: 10
            failureThreshold: 20
            periodSeconds: 10
            successThreshold: 1
          }
        }
      }
    ]
    ipAddress: {
      ports: [
        {
          port: 8443
          protocol: 'TCP'
        }
        {
          port: 3478
          protocol: 'UDP'
        }
        {
          port: 10001
          protocol: 'UDP'
        }
        {
          port: 8080
          protocol: 'TCP'
        }
        {
          port: 1900
          protocol: 'UDP'
        }
        {
          port: 8843
          protocol: 'TCP'
        }
        {
          port: 8880
          protocol: 'TCP'
        }
        {
          port: 6789
          protocol: 'TCP'
        }
        {
          port: 5514
          protocol: 'UDP'
        }
      ]
      type: 'Public'
    }
    osType: 'Linux'
    restartPolicy: 'Never'
    imageRegistryCredentials: [
      {
        server: 'hub.docker.com'
        username: RegistryUsername
        password: RegistryPassword
      }
    ]
    volumes: [
      {
        name: VolumeName
        azureFile: {
          shareName: DataShare.name
          storageAccountName: StorageAccount.name
          storageAccountKey: StorageAccount.listKeys().keys[0].value
        }
      }
    ]
  }
}
