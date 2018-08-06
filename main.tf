# A simple acme of using a HashiCorp-packer builder image 
# to bootstrap a gcloud autoscaler

provider "google" {
  region      = "${var.region}"
  project     = "${var.project_id}"
  credentials = "${file("${var.credentials_file_path}")}"
}

resource "google_compute_instance_template" "acme" {
  name           = "acme"
  machine_type   = "f1-micro"
  can_ip_forward = false

  tags = ["acme", "acme"]

  disk {
    source_image = "${var.base_image}"
  }

  network_interface {
    network = "default"

    access_config {
      # Ephemeral external IP
    }
  }

  metadata {
    ssh-keys = "root:${file("${var.public_key_path}")}"
  }
}

resource "google_compute_target_pool" "acme" {
  name          = "acme-target-pool"
  health_checks = ["${google_compute_http_health_check.acme.name}"]
}

resource "google_compute_instance_group_manager" "acme" {
  name = "acme"
  zone = "${var.region_zone}"

  instance_template  = "${google_compute_instance_template.acme.self_link}"
  target_pools       = ["${google_compute_target_pool.acme.self_link}"]
  base_instance_name = "acme-ubuntu"
}

resource "google_compute_http_health_check" "acme" {
  name                = "acme-basic-check"
  request_path        = "/"
  check_interval_sec  = 1
  healthy_threshold   = 1
  unhealthy_threshold = 3
  timeout_sec         = 1
}

resource "google_compute_autoscaler" "acme" {
  name   = "acme-autoscaler"
  zone   = "${var.region_zone}"
  target = "${google_compute_instance_group_manager.acme.self_link}"

  autoscaling_policy = {
    max_replicas    = 10
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.3
    }
  }
}

resource "google_compute_forwarding_rule" "acme" {
  name       = "acme-forwarding-rule"
  target     = "${google_compute_target_pool.acme.self_link}"
  port_range = "80"
}

resource "google_compute_firewall" "acme" {
  name    = "acme-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["acme"]
}
