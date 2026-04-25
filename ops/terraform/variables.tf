variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to create resources in."
}

variable "region" {
  type        = string
  description = "OCI region (e.g. eu-frankfurt-1)."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to authorize on the instance."
}

variable "domain" {
  type        = string
  description = "App domain (for your /opt/walks-server/.env)."
}

variable "install_host_nginx_certbot" {
  type        = bool
  default     = false
  description = "If true, installs host-level nginx + certbot. Note: conflicts with dockerized nginx if you run both."
}

variable "install_java" {
  type        = bool
  default     = false
  description = "If true, installs Java runtime on the VM (only needed if you run the jar directly on host)."
}

variable "shape" {
  type        = string
  default     = "VM.Standard.A1.Flex"
  description = "Compute shape."
}

variable "ocpus" {
  type        = number
  default     = 4
  description = "OCPUs for Flex shape."
}

variable "memory_in_gbs" {
  type        = number
  default     = 24
  description = "Memory (GB) for Flex shape."
}

variable "vcn_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VCN CIDR."
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Public subnet CIDR."
}

variable "instance_display_name" {
  type        = string
  default     = "walks-server"
  description = "Compute instance display name."
}

variable "image_ocid" {
  type        = string
  default     = ""
  description = "Optional: pin a specific image OCID. If empty, the newest Ubuntu 22.04 image compatible with the shape is used."
}
