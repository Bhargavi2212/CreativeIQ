variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_id" {
  type    = string
  default = "creativeiq-images"
}

variable "writer_service_account_emails" {
  type        = list(string)
  description = "Distinct SA emails (no serviceAccount: prefix) granted roles/artifactregistry.writer on the Docker repository."
  default     = []
}
