# The Client ID of the Azure Active Directory Service Principal.
variable "ARM_CLIENT_ID" {}

# The Client Secret of the Azure Active Directory Service Principal (used for authentication).
variable "ARM_CLIENT_SECRET" {}

# The Tenant ID of the Azure Active Directory where the Service Principal is located.
variable "ARM_TENANT_ID" {}

# The Subscription ID under which the Azure resources will be provisioned.
variable "ARM_SUBSCRIPTION_ID" {}

# The username for the Git repository.
variable "GIT_USERNAME" {
  type        = string
  description = "GitHub Username"
  default     = "bibishan-pandey"
}

# The password/access token for the Git repository.
variable "GIT_TOKEN" {
  type        = string
  description = "GitHub Personal Access Token"
}
