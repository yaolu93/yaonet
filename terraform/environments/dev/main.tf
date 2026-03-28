provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "gke" {
  source = "../../modules/gke"

  project_id                      = var.project_id
  region                          = var.region
  zone                            = var.zone
  environment                     = var.environment
  enable_runtime_infra            = var.enable_runtime_infra
  cluster_name                    = var.cluster_name
  network_name                    = var.network_name
  subnetwork_name                 = var.subnetwork_name
  subnetwork_cidr                 = var.subnetwork_cidr
  pods_secondary_range_name       = var.pods_secondary_range_name
  pods_secondary_range_cidr       = var.pods_secondary_range_cidr
  services_secondary_range_name   = var.services_secondary_range_name
  services_secondary_range_cidr   = var.services_secondary_range_cidr
  node_pool_name                  = var.node_pool_name
  node_count                      = var.node_count
  min_node_count                  = var.min_node_count
  max_node_count                  = var.max_node_count
  machine_type                    = var.machine_type
  artifact_registry_repository_id = var.artifact_registry_repository_id
  deletion_protection             = var.deletion_protection
}
