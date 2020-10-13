variable "zone" {
  default = "at-vie-1"
}

variable "vm" {
  default = "Linux Ubuntu 20.04 LTS 64-bit"
}

data "exoscale_compute_template" "instancepool" {
  zone = var.zone
  name = var.vm
}

data "exoscale_compute_template" "ubuntu" {
  zone = var.zone
  name = var.vm
}

resource "exoscale_instance_pool" "sprint_one_instance_pool" {
  zone               = var.zone
  name               = "sprint_one"
  description        = "This is the pool for sprint1"
  template_id        = data.exoscale_compute_template.instancepool.id
  service_offering   = "micro"
  size               = 3
  disk_size          = 10
  key_pair           = ""
  security_group_ids = [exoscale_security_group.sg.id]
  user_data = <<EOF
#!/bin/bash
set -e
apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo docker pull janoszen/http-load-generator:latest
sudo docker run -d --rm -p 80:8080 janoszen/http-load-generator
EOF
}

resource "exoscale_nlb" "sprint_one_nlb" {
  zone        = var.zone
  name        = "sprint_one_nlb"
  description = "This is the Network Load Balancer for sprint1"
}

resource "exoscale_nlb_service" "sprint_one_nlb_service" {
  zone             = exoscale_nlb.sprint_one_nlb.zone
  name             = "sprint_one_nlb_service"
  description      = "NLB service for sprint1"
  nlb_id           = exoscale_nlb.sprint_one_nlb.id
  instance_pool_id = exoscale_instance_pool.sprint_one_instance_pool.id
  protocol         = "tcp"
  port             = 80
  target_port      = 80
  strategy         = "round-robin"

  healthcheck {
    mode     = "http"
    port     = 80
    uri      = "/health"
    interval = 10
    timeout  = 10
    retries  = 1
  }
}