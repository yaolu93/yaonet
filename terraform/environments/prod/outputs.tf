output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_location" {
  value = module.gke.cluster_location
}

output "artifact_registry_repository_url" {
  value = module.gke.artifact_registry_repository_url
}

output "kubeconfig_command" {
  value = module.gke.kubeconfig_command
}
