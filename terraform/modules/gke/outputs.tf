output "cluster_name" {
  description = "GKE cluster name"
  value       = try(google_container_cluster.primary[0].name, null)
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = try(google_container_cluster.primary[0].location, null)
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = try(google_container_cluster.primary[0].endpoint, null)
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded)"
  value       = try(google_container_cluster.primary[0].master_auth[0].cluster_ca_certificate, null)
  sensitive   = true
}

output "vpc_name" {
  description = "VPC network name"
  value       = try(google_compute_network.vpc[0].name, null)
}

output "subnetwork_name" {
  description = "Subnetwork name"
  value       = try(google_compute_subnetwork.subnet[0].name, null)
}

output "artifact_registry_repository_url" {
  description = "Artifact Registry repository URL"
  value       = try("${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo[0].repository_id}", null)
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for this cluster"
  value       = try("gcloud container clusters get-credentials ${google_container_cluster.primary[0].name} --zone ${var.zone} --project ${var.project_id}", null)
}
