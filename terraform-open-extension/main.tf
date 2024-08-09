locals {
  values = "{applicationOwner: 'john.doe@example.com'}"
}

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
