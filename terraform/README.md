# Terraform Infrastructure for yaonet

This directory contains Terraform code for provisioning Google Cloud infrastructure for the yaonet project.

## Layout

- `modules/gke`: Reusable module that provisions:
  - Required GCP APIs
  - VPC network and subnetwork
  - GKE cluster and node pool
  - Artifact Registry repository
- `environments/dev`: Development environment composition
- `environments/prod`: Production environment composition

## Prerequisites

- Terraform >= 1.6
- Google Cloud SDK (`gcloud`) authenticated
- A GCP project with billing enabled
- IAM permissions to create GKE/network/registry resources

## Quick Start (dev)

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set project_id
terraform init
terraform plan
terraform apply
```

To run a zero-cost validation plan in dev, keep `enable_runtime_infra = false` in `terraform.tfvars`.

## Quick Start (prod)

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set project_id
terraform init
terraform plan
```

For a production dry run with near-zero cost, temporarily set `enable_runtime_infra = false` in `terraform.tfvars`. In that mode Terraform only enables the required Google APIs and skips GKE, node pools, networking, and Artifact Registry creation.

After apply, configure kubectl access:

```bash
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-id>
```

## Notes

- Keep environment-specific values in `terraform.tfvars` (not committed with secrets).
- Use separate state backends for dev/prod when moving to team usage (for example: GCS backend).
- This skeleton intentionally keeps application deployment outside Terraform. Continue deploying workloads with your existing Kubernetes manifests or Helm charts.
