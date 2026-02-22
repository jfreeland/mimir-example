# Look up the current user (joeyfreeland1) for escalation policies
data "grafana_oncall_user" "joey" {
  username = "joeyfreeland1"
}

# -----------------------------------------------------------------------------
# Escalation Chains
# -----------------------------------------------------------------------------

resource "grafana_oncall_escalation_chain" "devops" {
  name = "devops"
}

resource "grafana_oncall_escalation_chain" "platform" {
  name = "platform"
}

# -----------------------------------------------------------------------------
# Escalation Policies
# -----------------------------------------------------------------------------

resource "grafana_oncall_escalation" "devops_notify" {
  escalation_chain_id = grafana_oncall_escalation_chain.devops.id
  type                = "notify_persons"
  persons_to_notify   = [data.grafana_oncall_user.joey.id]
  position            = 0
  important           = false
}

resource "grafana_oncall_escalation" "platform_notify" {
  escalation_chain_id = grafana_oncall_escalation_chain.platform.id
  type                = "notify_persons"
  persons_to_notify   = [data.grafana_oncall_user.joey.id]
  position            = 0
  important           = true
}

# -----------------------------------------------------------------------------
# Integrations (Alertmanager webhook receivers)
# -----------------------------------------------------------------------------

resource "grafana_oncall_integration" "devops_alerts" {
  name = "devops-alerts"
  type = "alertmanager"

  default_route {
    escalation_chain_id = grafana_oncall_escalation_chain.devops.id
  }
}

resource "grafana_oncall_integration" "platform_alerts" {
  name = "platform-alerts"
  type = "alertmanager"

  default_route {
    escalation_chain_id = grafana_oncall_escalation_chain.platform.id
  }
}

# -----------------------------------------------------------------------------
# Outputs - webhook URLs for alertmanager.yaml
# -----------------------------------------------------------------------------

output "devops_webhook_url" {
  value       = grafana_oncall_integration.devops_alerts.link
  description = "Webhook URL for the devops Alertmanager receiver"
}

output "platform_webhook_url" {
  value       = grafana_oncall_integration.platform_alerts.link
  description = "Webhook URL for the platform Alertmanager receiver"
}
