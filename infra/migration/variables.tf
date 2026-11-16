variable "source_db_password" {
  description = "Root password of the legacy MySQL (same as db_password in infra/onprem)"
  type        = string
  sensitive   = true
}
