terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google",
      version = "~> 5.30"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.30"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

provider "google" {
  credentials = var.credentials != "" ? file(var.credentials) : null
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  credentials = var.credentials != "" ? file(var.credentials) : null
  project     = var.project_id
  region      = var.region
}

module "project" {
  source     = "./modules/project"
  project_id = var.project_id
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region
  depends_on = [module.project]
}

module "firestore" {
  source     = "./modules/firestore"
  project_id = var.project_id
  region     = var.region
  depends_on = [module.project]
}

module "vertex_ai" {
  source     = "./modules/vertex_ai"
  project_id = var.project_id
  region     = var.region
  depends_on = [module.project]
}

module "wallet" {
  source     = "./modules/wallet"
  project_id = var.project_id
  depends_on = [module.project]
}

module "cloud_functions" {
  source         = "./modules/cloud_functions"
  project_id     = var.project_id
  region         = var.region
  receipt_bucket = module.storage.bucket_name
  depends_on     = [module.project, module.storage]
}

module "firebase" {
  source             = "./modules/firebase"
  project_id         = var.project_id
  chat_function_name = "chat-assistant"
  depends_on         = [module.project, module.cloud_functions]
}

module "monitoring" {
  source     = "./modules/monitoring"
  project_id = var.project_id
  region     = var.region
  depends_on = [module.project]
}

# Outputs for CI/CD
output "project_id" {
  value = var.project_id
}

output "receipt_bucket" {
  value = module.storage.bucket_name
}

output "functions_sa_email" {
  value = module.cloud_functions.functions_sa_email
}

output "backend_functions_url" {
  value = module.cloud_functions.chat_url
}

output "hosting_url" {
  value = module.firebase.hosting_url
}

output "hosting_site_id" {
  value = module.firebase.hosting_site_id
}
