variable "my_ip" {
  description = "My laptop's public IP, as x.x.x.x/32"
  type        = string
}

variable "db_password" {
  description = "Root password for the legacy MySQL database"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9]{12,}$", var.db_password))
    error_message = "Use at least 12 letters and numbers only (no symbols)."
  }
}

variable "repo_url" {
  description = "Where the server downloads the app code from"
  type        = string
  default     = "https://github.com/Haroon-Azam/aws-migration-lab.git"
}
