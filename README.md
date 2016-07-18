---
services: app-service
platforms: ruby
author: devigned
---

# Manage Azure websites with Ruby

This sample demonstrates how to manage your Azure websites using a ruby client.

**On this page**

- [Run this sample](#run)
- [What does example.rb do?](#sample)
    - [Create a server farm](#create-server-farm)
    - [Create a website](#create-website)
    - [List websites](#list-websites)
    - [Get website details](#details)
    - [Delete a website](#update)

<a id="run"></a>
1. If you don't already have it, [install Ruby and the Ruby DevKit](https://www.ruby-lang.org/en/documentation/installation/).

1. If you don't have bundler, install it.

    ```
    gem install bundler
    ```

1. Clone the repository.

    ```
    git clone https://github.com:Azure-Samples/app-service-web-ruby-manage.git
    ```

1. Install the dependencies using bundle.

    ```
    cd app-service-web-ruby-manage
    bundle install
    ```

1. Create an Azure service principal either through
    [Azure CLI](https://azure.microsoft.com/documentation/articles/resource-group-authenticate-service-principal-cli/),
    [PowerShell](https://azure.microsoft.com/documentation/articles/resource-group-authenticate-service-principal/)
    or [the portal](https://azure.microsoft.com/documentation/articles/resource-group-create-service-principal-portal/).

1. Set the following environment variables using the information from the service principle that you created.

    ```
    export AZURE_TENANT_ID={your tenant id}
    export AZURE_CLIENT_ID={your client id}
    export AZURE_CLIENT_SECRET={your client secret}
    export AZURE_SUBSCRIPTION_ID={your subscription id}
    ```

    > [AZURE.NOTE] On Windows, use `set` instead of `export`.

1. Run the sample.

    ```
    bundle exec ruby example.rb
    ```

<a id="sample"></a>
## What does example.rb do?

The sample creates, lists and updates a website.
It starts by setting up a ResourceManagementClient object using your subscription and credentials.

```ruby
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
provider = MsRestAzure::ApplicationTokenProvider.new(
    ENV['AZURE_TENANT_ID'],
    ENV['AZURE_CLIENT_ID'],
    ENV['AZURE_CLIENT_SECRET'])
credentials = MsRest::TokenCredentials.new(provider)
web_client = Azure::ARM::Web::WebSiteManagementClient.new(credentials)
resource_client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
resource_client.subscription_id = web_client.subscription_id = subscription_id
```

The sample then sets up a resource group in which it will create the website.

```ruby
resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
  rg.location = WEST_US
end

resource_group_params.class.class

resource_client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)
```

<a id="create-server-farm"></a>
### Create a server farm

Create a server farm to host your website.

```ruby
server_farm_params = Azure::ARM::Web::Models::ServerFarmWithRichSku.new.tap do |sf|
  sf.location = WEST_US
  sf.sku = Azure::ARM::Web::Models::SkuDescription.new.tap do |sd|
    sd.name = 'S1'
    sd.capacity = 1
    sd.tier = 'Standard'
  end
end
print_item web_client.server_farms.create_or_update_server_farm(GROUP_NAME, SERVER_FARM_NAME, server_farm_params)
```

<a id="create-website"></a>
### Create a website

```ruby
site_params = Azure::ARM::Web::Models::Site.new.tap do |site|
  site.location = WEST_US
  site.properties = Azure::ARM::Web::Models::SiteProperties.new.tap do |props|
    props.server_farm_id
  end
end
web_client.sites.create_or_update_site(GROUP_NAME, SITE_NAME, site_params)
```

<a id="list-websites"></a>
### List websites in the resourcegroup

```ruby
web_client.sites.get_sites(GROUP_NAME).each{ |site| print_item site }
```

<a id="details"></a>
### Get details for the given website

```ruby
web_client.sites.get_site(GROUP_NAME, SITE_NAME)
```

<a id="delete-site"></a>
### Delete a website

```ruby
web_client.sites.delete_site(GROUP_NAME, SITE_NAME)
```

At this point, the sample also deletes the resource group that it created.

```ruby
resource_client.resource_groups.delete(GROUP_NAME)
``` 


## More information
Please refer to [Azure SDK for Node](https://github.com/Azure/azure-sdk-for-node) for more information.
