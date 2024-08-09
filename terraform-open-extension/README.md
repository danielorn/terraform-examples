# Introduction
This demo shows how to call the microsoft graph api from within Terraform using a [local-exec](https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec) [provisioner](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax). This is useful for accessing functionality not yet wrapped in any terraform provider.

This demo sets an [open extension](https://learn.microsoft.com/en-us/graph/extensibility-open-users) on a Entra ID group, but the strategy used can be generalized to fit any scenario where microsoft graph api needs to be called.

# Prerequisites
- [Install Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Install Terraform](https://developer.hashicorp.com/terraform/install)

# Details

## The Set-OpenExtension.ps1 script
The `Set-OpenExtension.ps1` script adds an open extension with the given name and value to the specified entity.

To create or update an extension with name `com.example.contacts` and value `applicationOwner` set to `john.doe@example.com` on the `group` with objectId `9197d8cf-d4c0-4669-aba9-8f048f5b020f` the script can be called as below

```powershell
./Set-OpenExtension.ps1 `
    -Type groups `
    -ObjectId 9197d8cf-d4c0-4669-aba9-8f048f5b020f `
    -Name com.example.contacts `
    -Values "{applicationOwner: 'john.doe@example.com'}"
```

### Authentication

Terraform authenticates to Azure using Azure CLI. When executing a shell script through the local-exec provisioner [a bearer token can be retrieved via Azure CLI](https://learn.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-get-access-token). This token can be used in API calls to the micrsoft graph api

```sh
az account get-access-token --resource-type ms-graph --query accessToken -o tsv
```

## Calling the Script from Terraform
There are two ways to call the script from Terraform where Option 1 is slighlty more complex but the more robust solution.

### Option 1 - Add a provider block to a terraform_data resource

```terraform
# Example 1 Provisioner inside a terraform_data resource that references 
# the azuread_group resource
#
# Benefits
#  - The open extension have it's own lifecycle and will be updated if 
#    the values in the triggers_replace field change
# Drawbacks
#  - Looping groups will require a loop also in the terraform_data 
#    resource to match each group

resource "azuread_group" "group1" {
  display_name = "TESTGROUP1"
  security_enabled = true
}

resource "terraform_data" "group1_openextension" {
  # Provisioner will run every time the values change
  triggers_replace = [
    local.values
  ]

  provisioner "local-exec" {
    command = <<EOT
      ./Set-OpenExtension.ps1 `
        -Type Groups `
        -ObjectId ${azuread_group.group1.id} `
        -Name com.example.contacts `
        -Values "${local.values}"
    EOT
    interpreter = ["pwsh", "-Command"]
  }
}
```

### Option 2 - Add a provider block to the group creation resource

```tf
# Example 2 Provisioner inside the azuread_group resource
# Benefits
#  - More clear dependency between the group and the open extension, simpler looping
# Drawbacks
#  - The provisioner executes only when the group is created, not when the 
#    group or values are updated
resource "azuread_group" "group2" {
  display_name = "TESTGROUP2"
  security_enabled = true

  provisioner "local-exec" {
    command = <<EOT
      ./Set-OpenExtension.ps1 `
        -Type Groups `
        -ObjectId ${self.id} `
        -Name com.example.contacts `
        -Values "${local.values}"
    EOT
    interpreter = ["pwsh", "-Command"]
  }
}
```

