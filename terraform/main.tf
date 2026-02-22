terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.15.0"
    }
  }
}

provider "grafana" {
  url        = "https://jfreeland.grafana.net"
  auth       = var.grafana_api_key
  oncall_url = "https://oncall-prod-us-central-0.grafana.net/oncall"
}

variable "grafana_api_key" {
  type      = string
  sensitive = true
}
