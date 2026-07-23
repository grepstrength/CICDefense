variable "subscription_id" {
  description = "The Azure Subscription ID where all lab resource will be created."
  type        = string
}
variable "location" {
  description = "The Azure region fo all resources."
  type        = string
  default     = "eastus2"
}
variable "project_name" {
  description = "Short name used as a prefix when naming resouces."
  type        = string
  default     = "cicdefense"
}
variable "tags" {
  description = "Tags applied to every resource for cost tracking and identification."
  type        = map(string)
  default = {
    environment = "lab"
    project     = "cicdefense"
    managed_by  = "terraform"
  }
}

variable "admin_username" {
  description = "Administrator username for all lab VMs."
  type        = string
  default     = "labmin"
  validation {
    condition = !contains(
      ["admin", "administratr", "root", "guest", "user", "test"],
      lower(var.admin_username)
    )
    error_message = "Azure reserves certain usernames. Choose something other than admin, administrator, root, guest, user, or test."
  }
}

variable "admin_password" {
  description = "Administrator password for all lab VMs. Supplied via terraform.tfvars (gitignored)."
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters to satisfy Azure complexity requirements."
  }
}
variable "vm_size" {
  description = "Azure VM size for lab machines. B-series are burstable and cheaper."
  type        = string
  default     = "Standard_B2ms"
}