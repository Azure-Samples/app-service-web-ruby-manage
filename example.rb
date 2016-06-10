#!/usr/bin/env ruby

require 'azure_mgmt_resources'
require 'azure_mgmt_web'
require 'dotenv'
require 'haikunator'

Dotenv.load(File.join(__dir__, './.env'))

WEST_US = 'westus'
GROUP_NAME = 'azure-sample-group'
SERVER_FARM_NAME = 'sample-server-farm'
SITE_NAME = Haikunator.haikunate(100)


# This script expects that the following environment vars are set:
#
# AZURE_TENANT_ID: with your Azure Active Directory tenant id or domain
# AZURE_CLIENT_ID: with your Azure Active Directory Application Client ID
# AZURE_CLIENT_SECRET: with your Azure Active Directory Application Secret
# AZURE_SUBSCRIPTION_ID: with your Azure Subscription Id
#
def run_example
  #
  # Create the Resource Manager Client with an Application (service principal) token provider
  #
  subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
  provider = MsRestAzure::ApplicationTokenProvider.new(
      ENV['AZURE_TENANT_ID'],
      ENV['AZURE_CLIENT_ID'],
      ENV['AZURE_CLIENT_SECRET'])
  credentials = MsRest::TokenCredentials.new(provider)
  web_client = Azure::ARM::Web::WebSiteManagementClient.new(credentials)
  resource_client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
  resource_client.subscription_id = web_client.subscription_id = subscription_id

  #
  # Create a resource group
  #
  resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = WEST_US
  end

  resource_group_params.class.class

  puts 'Create Resource Group'
  print_item resource_client.resource_groups.create_or_update(GROUP_NAME, resource_group_params)

  #
  # Create a Server Farm for your WebApp
  #
  puts 'Create a Server Farm for your WebApp'
  server_farm_params = Azure::ARM::Web::Models::ServerFarmWithRichSku.new.tap do |sf|
    sf.location = WEST_US
    sf.sku = Azure::ARM::Web::Models::SkuDescription.new.tap do |sd|
      sd.name = 'S1'
      sd.capacity = 1
      sd.tier = 'Standard'
    end
  end
  print_item web_client.server_farms.create_or_update_server_farm(GROUP_NAME, SERVER_FARM_NAME, server_farm_params)

  #
  # Create a Site to be hosted in the Server Farm
  #
  puts 'Create a Site to be hosted in the Server Farm'
  site_params = Azure::ARM::Web::Models::Site.new.tap do |site|
    site.location = WEST_US
    site.properties = Azure::ARM::Web::Models::SiteProperties.new.tap do |props|
      props.server_farm_id
    end
  end
  print_item web_client.sites.create_or_update_site(GROUP_NAME, SITE_NAME, site_params)

  #
  # List Sites by Resource Group
  #
  puts 'List Sites by Resource Group'
  web_client.sites.get_sites(GROUP_NAME).each{ |site| print_item site }

  #
  # Get a single Site
  #
  puts 'Get a single Site'
  site = web_client.sites.get_site(GROUP_NAME, SITE_NAME)
  print_item site

  puts "Your site and server farm have been created. You can now go and visit at http://#{site.default_host_name}./nPress enter to delete the site and server farm."
  gets

  #
  # Delete a Site
  #
  puts 'Deleting the Site'
  web_client.sites.delete_site(GROUP_NAME, SITE_NAME)

  #
  # Delete the Resource Group
  #
  puts 'Deleting the resource group'
  resource_client.resource_groups.delete(GROUP_NAME)

end

def print_item(group)
  puts "\tName: #{group.name}"
  puts "\tId: #{group.id}"
  puts "\tLocation: #{group.location}"
  puts "\tTags: #{group.tags}"
  print_properties(group.properties)
end

def print_properties(props)
  if props.respond_to? :provisioning_state
    puts "\tProperties:"
    puts "\t\tProvisioning State: #{props.provisioning_state}"
  end
  puts "\n\n"
end

if $0 == __FILE__
  run_example
end


