# Note

This repository has been archived and is no longer maintained.

# Khulnasoft for Bosh

## Prepare release

**Clone repository and checkout to branch v4.4.0**
```
git clone https://github.com/khulnasoft/khulnasoft-bosh
cd khulnasoft-bosh
git checkout v4.4.0
```

**Single or Multi Node Khulnasoft Cluster**

First of all it will be neccessary to determine the kind of deployment. If it is a Multi Node Cluster with more than one Worker Node there will be some changes to apply prior to the Release creation:
- In [manifest/khulnasoft-agent-cluster.yml](https://github.com/khulnasoft/khulnasoft-bosh/blob/v4.4.0/manifest/khulnasoft-agent-cluster.yml) add a new property (khulnasoft_server_worker_address_#) for each extra worker node. The IPs can be assigned before the deployment. Example:
```yaml
      properties:
          khulnasoft_server_address: 172.31.32.4 
          khulnasoft_server_registration_address: 172.31.32.4
          khulnasoft_server_worker_address: 172.31.32.5
          khulnasoft_server_worker_address_2: 172.31.32.6
          khulnasoft_server_worker_address_3: 172.31.32.7
          khulnasoft_server_protocol: "tcp"
          khulnasoft_agents_prefix: "bosh-"
          khulnasoft_agent_profile: "generic"
          khulnasoft_multinode: true
```

- Add another server tag for each extra worker node on [jobs/khulnasoft-agent/templates/config/ossec_cluster.conf.erb](https://github.com/khulnasoft/khulnasoft-bosh/blob/v4.4.0/jobs/khulnasoft-agent/templates/config/ossec_cluster.conf.erb). Example:
```xml
    <server>
      <address><%= p("khulnasoft_server_worker_address") %></address>
      <port>1514</port>
      <protocol><%= p("khulnasoft_server_protocol") %></protocol>
    </server>
    <server>
      <address><%= p("khulnasoft_server_worker_address_2") %></address>
      <port>1514</port>
      <protocol><%= p("khulnasoft_server_protocol") %></protocol>
    </server>
    <server>
      <address><%= p("khulnasoft_server_worker_address_3") %></address>
      <port>1514</port>
      <protocol><%= p("khulnasoft_server_protocol") %></protocol>
    </server>
    <server>
      <address><%= p("khulnasoft_server_address") %></address>
      <port>1514</port>
      <protocol><%= p("khulnasoft_server_protocol") %></protocol>
    </server>
```
Where **khulnasoft_server_worker_address_2** and **khulnasoft_server_worker_address_3** are the properties added on the previous step.

**Download blobs from the `S3` repository using Curl**
```
mkdir -p blobs/khulnasoft
curl https://packages.wazuh.com/bosh/khulnasoft-manager-4.4.0.tar.gz -o blobs/khulnasoft/khulnasoft-manager.tar.gz
curl https://packages.wazuh.com/bosh/khulnasoft-agent-4.4.0.tar.gz -o blobs/khulnasoft/khulnasoft-agent.tar.gz
```

**Add blobs to Bosh environment**
```
bosh -e your_bosh_environment add-blob blobs/khulnasoft/khulnasoft-manager.tar.gz /khulnasoft/khulnasoft-manager.tar.gz
bosh -e your_bosh_environment add-blob blobs/khulnasoft/khulnasoft-agent.tar.gz /khulnasoft/khulnasoft-agent.tar.gz
```

**Upload blobs to the blob store**
```
bosh -e your_bosh_environment upload-blobs
```

**Create release**
```
bosh -e your_bosh_environment create-release --final --version=4.4.0 --force
```

**Upload release**
```
bosh -e your_bosh_environment upload-release
```

## Deploy Khulnasoft Server

**Deploy Master Node**
Execute the following command to deploy the Master Node:
```
bosh -e your_bosh_environment -d khulnasoft-manager deploy manifest/khulnasoft-manager.yml
```

**Check deployment status**

Get instance name.
```
bosh -e your_bosh_environment vms
```
If the deployment succeeded the **Process State** will be **running**.

For further checks connect to the instance using ssh and the Instance Name obtained in the previous command.
```
bosh -e your_bosh_environment -d khulnasoft-manager ssh InstanceName
```
Check Khulnasoft Manager status.
```
sudo -i
/var/ossec/bin/khulnasoft-control status
```
The result must be like this:
```
khulnasoft-clusterd is running...
khulnasoft-modulesd is running...
khulnasoft-monitord is running...
khulnasoft-logcollector is running...
khulnasoft-remoted is running...
khulnasoft-syscheckd is running...
khulnasoft-analysisd is running...
khulnasoft-maild not running...
khulnasoft-execd is running...
khulnasoft-db is running...
khulnasoft-authd is running...
khulnasoft-agentlessd not running...
khulnasoft-integratord not running...
khulnasoft-dbd not running...
khulnasoft-csyslogd not running...
khulnasoft-apid is running...
```

**Deploy Worker Node**

Execute this step only if you need to deploy a multi-node Khulnasoft Cluster.
Configure [manifest/khulnasoft-manager-worker.yml](https://github.com/khulnasoft/khulnasoft-bosh/blob/v4.4.0/manifest/khulnasoft-manager-worker.yml) according to the number of **instances** you want to create.

Obtain the address of your recently deployed Khulnasoft Manager and update the `khulnasoft_master_address` setting in the [manifest/khulnasoft-manager-worker.yml](https://github.com/khulnasoft/khulnasoft-bosh/blob/v4.4.0/manifest/khulnasoft-manager-worker.yml) runtime configuration file.
Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Execute the following command to deploy the Worker Node:
```
bosh -e your_bosh_environment -d khulnasoft-manager-worker deploy manifest/khulnasoft-manager-worker.yml
```
## Deploy Khulnasoft Agents

**Single Node Khulnasoft Cluster**

Obtain the address of your recently deployed Khulnasoft Manager and update the `khulnasoft_server_address` and `khulnasoft_server_registration_address` settings in the [manifest/khulnasoft-agent.yml](https://github.com/khulnasoft/khulnasoft-bosh/blob/v4.4.0/manifest/khulnasoft-agent.yml) runtime configuration file.

**NOTE: `khulnasoft_server_worker_address` will not be used in this deployment but it must have a value.**

Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=khulnasoft-agent-addons manifest/khulnasoft-agent.yml
```

Redeploy your initial manifest to make Bosh install and configure the Khulnasoft Agent on target instances.

**Multi Node Khulnasoft Cluster**

Obtain the address of your recently deployed Khulnasoft Manager Master and Worker nodes and update the following settings in the [manifest/khulnasoft-agent-cluster.yml](https://github.com/khulnasoft/khulnasoft-bosh/blob/v4.4.0/manifest/khulnasoft-agent-cluster.yml) runtime configuration file.
- `khulnasoft_server_address` (Master Node IP)
- `khulnasoft_server_registration_address` (Master Node IP) 
- `khulnasoft_server_worker_address` (Worker Node IP). If there are more than one worker nodes assign the values to the `khulnasoft_server_worker_address_#` properties.

Use the following command to obtain the IP:
```
bosh -e your_bosh_environment vms
```

Update your Director runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=khulnasoft-agent-addons manifest/khulnasoft-agent-cluster.yml
```

Redeploy your initial manifest to make Bosh install and configure the Khulnasoft Agent on target instances.

### Deploy Khulnasoft Agents using SSL

You can register your Khulnasoft Agents using SSL  to secure the communication as described in [Agent verification using SSL](https://documentation.khulnasoft.com/current/user-manual/registering/host-verification-registration.html#available-options-to-verify-the-hosts)

To pass your generated `sslagent.cert` and `sslagent.key` files to your runtime configuration you simply have to include them in `khulnasoft_agent_cert` and `khulnasoft_agent_key` parameters like in the following example:


```yaml
---
  releases:
  - name: "khulnasoft"
    version: 4.4.0

  addons:
  - name: khulnasoft
    release: 4.4.0
    jobs:
    - name: khulnasoft-agent
      release: khulnasoft
      properties:
          khulnasoft_server_address: 172.31.32.4
          khulnasoft_server_registration_address: 172.31.32.4
          khulnasoft_server_worker_address: 172.31.32.5
          khulnasoft_server_protocol: "tcp"
          khulnasoft_agents_prefix: "bosh-"
          khulnasoft_agent_profile: "generic"
          khulnasoft_agent_cert: |
            -----BEGIN CERTIFICATE-----
            MIIE6jCCAtICCQCeRsKNJC058zANBgkqhkiG9w0BAQsFADAsMQswCQYDVQQGEwJV
            UzELMAkGA1UECAwCQ0ExEDAOBgNVBAoMB01hbmFnZXIwHhcNMjAwMjEwMTExNzQ5
            WhcNMjEwMjA5MTExNzQ5WjBCMQswCQYDVQQGEwJYWDEVMBMGA1UEBwwMRGVmYXVs
            ...
            -----END CERTIFICATE-----
          khulnasoft_agent_key: |
            -----BEGIN PRIVATE KEY-----
            MIIJQQIBADANBgkqhkiG9w0BAQEFAASCCSswggknAgEAAoICAQDgSRkPQbeFBXWE
            2fG1XZEkJyAVP/wjcuGWRmIufexw/tpVF0+AADhafJwpre+9zYYFDwPeYSN11zAH
            E5KGDhqDh9hie3xnTOllHfjXbvijuqoLkNUU6HsssGFI/epA1Yfyl220ZNE5AZCL
            ...
            -----END PRIVATE KEY-----          
    exclude:
      deployments: [khulnasoft-manager]
```

Then, update your runtime configuration by executing:

```
bosh -e your_bosh_environment update-runtime-config --name=khulnasoft-agent-addons manifest/khulnasoft-agent.yml
```

This way, your cert and key will be rendered under `/var/ossec/<random_id>/etc/` and used in the registration process and any communications between the Agent and Manager.

## Delete Procedure
**Manager Worker deployment**
```
bosh -e your_bosh_environment -d khulnasoft-manager-worker deld
```
**Manager Master deployment**
```
bosh -e your_bosh_environment -d khulnasoft-manager deld
```
**Agent Deployment**
```
bosh -e your_bosh_environment update-runtime-config --name=khulnasoft-agent-addons manifest/khulnasoft-agent-delete.yml
```
**Khulnasoft Release**
```
bosh -e your_bosh_environment delete-release khulnasoft/4.4.0
rm -rf dev_releases/khulnasoft/
rm -rf releases/khulnasoft/
```
**Blobs**
```
bosh -e your_bosh_environment remove-blob /khulnasoft/khulnasoft-agent.tar.gz
bosh -e your_bosh_environment remove-blob /khulnasoft/khulnasoft-manager.tar.gz
```

## General usage notes

### Khulnasoft deployed via Docker

If your Khulnasoft Docker deployment does not contain any extra configurations, it will be necessary to modify the `khulnasoft_server_protocol` property in the [manifest/khulnasoft-agent.yml](https://github.com/khulnasoft/khulnasoft-bosh/blob/master/manifest/khulnasoft-agent.yml) to `UDP` given that this bosh agent will attempt to connect using the port 1514 that is reserved to UDP in the Docker deployment.

### Cloud Foundry resources registration

Once your Bosh release is completed successfully the agents will be able to register themselves normally against any Khulnasoft manager. If you choose to use an external manager or deployed agents across different clusters, you might face duplicated IP Addresses.

Khulnasoft chooses to primarily identify hosts with their IP Addresses but it is possible to change that by modifying the tag `<use_source_ip>` to **no** inside the Khulnasoft Manager's `ossec.conf` file.
