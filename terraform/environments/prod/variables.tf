variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-east1-b"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "enable_runtime_infra" {
  description = "When false, only required Google APIs are enabled for a zero-cost validation plan"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "yaonet-prod-cluster"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "yaonet-prod-vpc"
}

variable "subnetwork_name" {
  description = "Subnetwork name"
  type        = string
  default     = "yaonet-prod-subnet"
}

variable "subnetwork_cidr" {
  description = "Subnetwork CIDR"
  type        = string
  default     = "10.110.0.0/20"
}

variable "pods_secondary_range_name" {
  description = "Pods secondary range name"
  type        = string
  default     = "pods"
}

variable "pods_secondary_range_cidr" {
  description = "Pods secondary CIDR"
  type        = string
  default     = "10.120.0.0/16"
}

variable "services_secondary_range_name" {
  description = "Services secondary range name"
  type        = string
  default     = "services"
}

variable "services_secondary_range_cidr" {
  description = "Services secondary CIDR"
  type        = string
  default     = "10.130.0.0/20"
}

variable "node_pool_name" {
  description = "Node pool name"
  type        = string
  default     = "default-pool"
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum node count"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum node count"
  type        = number
  default     = 8
}

variable "machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
  default     = "yaonet-prod"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
