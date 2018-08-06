## Set Variables for our cloud

variable "region" {
  default = "us-west2"
}

variable "region_zone" {
  default = "us-west2-a"
}

variable "project_id" {
  description = "The ID of the Google Cloud project"
  default     = "22764302422"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "~/.gcloud/account.json"
}

variable "public_key_path" {
  description = "Path to file containing public key"
  default     = "~/.ssh/gcloud_id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to file containing private key"
  default     = "~/.ssh/gcloud_id_rsa"
}

variable "base_image" {
  description = "Name of Base Image for Packer Run"
  default = "acme-ubuntu-1804-bionic-base-1533426149"
}
