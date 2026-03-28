locals {
  required_services = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com"
  ])
}

resource "google_project_service" "required" {
  for_each           = local.required_services
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  count                   = var.enable_runtime_infra ? 1 : 0
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "subnet" {
  count         = var.enable_runtime_infra ? 1 : 0
  name          = var.subnetwork_name
  ip_cidr_range = var.subnetwork_cidr
  region        = var.region
  network       = google_compute_network.vpc[0].id

  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_range_cidr
  }

  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_range_cidr
  }
}

resource "google_container_cluster" "primary" {
  count                    = var.enable_runtime_infra ? 1 : 0
  name                     = var.cluster_name
  location                 = var.zone
  network                  = google_compute_network.vpc[0].name
  subnetwork               = google_compute_subnetwork.subnet[0].name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = var.deletion_protection

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [google_project_service.required]
}

resource "google_container_node_pool" "primary_nodes" {
  count      = var.enable_runtime_infra ? 1 : 0
  name       = var.node_pool_name
  location   = var.zone
  cluster    = google_container_cluster.primary[0].name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      project     = "yaonet"
    }

    tags = ["gke", "yaonet", var.environment]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_artifact_registry_repository" "docker_repo" {
  count         = var.enable_runtime_infra ? 1 : 0
  location      = var.region
  repository_id = var.artifact_registry_repository_id
  description   = "Docker repository for yaonet (${var.environment})"
  format        = var.artifact_registry_format

  depends_on = [google_project_service.required]
}
