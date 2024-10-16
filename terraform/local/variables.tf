variable "db_root_password" {
  description = "The root password for the database"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_user" {
  description = "The database user"
  type        = string
}

variable "db_password" {
  description = "The password for the database user"
  type        = string
}

variable "docker_registry_username" {
  description = "The username for the Docker registry"
  type        = string
}

variable "docker_registry_password" {
  description = "The password for the Docker registry"
  type        = string
}

variable "docker_registry_email" {
  description = "The email for the Docker registry"
  type        = string
}