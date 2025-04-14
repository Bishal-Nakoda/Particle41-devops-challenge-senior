# local variables for subnet cidr ranges
locals {
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Enabling the APIs
resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  project  = var.project_id
  service  = each.key
}

# Creating custom vpc
resource "google_compute_network" "vpc_network" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
}

# Create Public Subnets
resource "google_compute_subnetwork" "public_subnet" {
  count                    = length(local.public_subnet_cidrs)
  name                     = "public-subnet-${count.index + 1}"
  network                  = google_compute_network.vpc_network.id
  region                   = "us-central1"
  ip_cidr_range            = local.public_subnet_cidrs[count.index]
  private_ip_google_access = false

  # Public subnets do not need NAT, but you may want to set up firewall rules separately
}

# Create Private Subnets 
resource "google_compute_subnetwork" "private_subnet" {
  count                    = length(local.private_subnet_cidrs)
  name                     = "private-subnet-${count.index + 1}"
  network                  = google_compute_network.vpc_network.id
  region                   = "us-central1"
  ip_cidr_range            = local.private_subnet_cidrs[count.index]
  private_ip_google_access = true

  # Private subnets will use NAT for outbound access
}

# Create a NAT Gateway for Private Subnets to access the internet
resource "google_compute_router" "router" {
  name    = "router"
  network = google_compute_network.vpc_network.id
  region  = "us-central1"
}

# Creating a router for private subnets to access the internet
resource "google_compute_router_nat" "router_nat" {
  name                               = "router-nat"
  router                             = google_compute_router.router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}

# As cloud run is managed service, creating vpc connector to connect with it
resource "google_vpc_access_connector" "vpc_connector" {
  name          = "serverless-conn"
  machine_type  = "f1-micro"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"
}

# Serverless Cloud run
resource "google_cloud_run_service" "flask_service" {
  name     = "flask-ip-api"
  location = var.region

  template {
    spec {
      containers {
        image = var.docker_image
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.vpc_connector.id
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Making it Public 
resource "google_cloud_run_service_iam_member" "allow_all" {
  location = google_cloud_run_service.flask_service.location
  service  = google_cloud_run_service.flask_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# BElow is all data and resource block is for creating Load balancer
data "google_compute_global_address" "default" {
  name = var.ip
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = "lb-cert"

  managed {
    domains = [var.domain]
  }
}

resource "google_compute_ssl_policy" "ssl-policy" {
  name            = "ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "cloudrun-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.flask_service.name
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "cloud-run-backend"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTPS"
  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }
}

resource "google_compute_url_map" "urlmap" {
  name            = "lb"
  default_service = google_compute_backend_service.backend_service.id
}

resource "google_compute_target_https_proxy" "default" {
  name             = "test-proxy"
  url_map          = google_compute_url_map.urlmap.id
  ssl_policy       = google_compute_ssl_policy.ssl-policy.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
}


resource "google_compute_global_forwarding_rule" "default" {
  name       = "forwarding-rule"
  port_range = "443"
  target     = google_compute_target_https_proxy.default.id
  ip_address = data.google_compute_global_address.default.id
}
