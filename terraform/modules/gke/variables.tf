variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
}

variable "environment" {
  description = "Environment name, for example dev or prod"
  type        = string
}

variable "enable_runtime_infra" {
  description = "When false, only required project APIs are enabled and no billable runtime infrastructure is created"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "network_name" {
  description = "VPC network name"
  type        = string
}

variable "subnetwork_name" {
  description = "Subnetwork name"
  type        = string
}

variable "subnetwork_cidr" {
  description = "CIDR block for subnetwork"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Secondary range name for Pods"
  type        = string
}

variable "pods_secondary_range_cidr" {
  description = "Secondary CIDR block for Pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Secondary range name for Services"
  type        = string
}

variable "services_secondary_range_cidr" {
  description = "Secondary CIDR block for Services"
  type        = string
}

variable "node_pool_name" {
  description = "GKE node pool name"
  type        = string
}

variable "node_count" {
  description = "Initial node count"
  type        = number
}

variable "min_node_count" {
  description = "Minimum node count for autoscaling"
  type        = number
}

variable "max_node_count" {
  description = "Maximum node count for autoscaling"
  type        = number
}

variable "machine_type" {
  description = "Machine type for GKE worker nodes"
  type        = string
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
}

variable "artifact_registry_format" {
  description = "Artifact Registry format"
  type        = string
  default     = "DOCKER"
}

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = false
}
