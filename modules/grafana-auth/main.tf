data "grafana_cloud_stack" "graf_stack" {
  slug = var.graf_stack_slug
}

resource "grafana_cloud_access_policy" "alloy_pol" {
  region       = data.grafana_cloud_stack.graf_stack.region_slug
  name         = "alloy-pol"
  display_name = "alloy-pol"

  scopes = [
    "metrics:write",
    "logs:write",
    "traces:write",
    "profiles:write",
    "fleet-management:read"
  ]

  realm {
    type       = "org"
    identifier = data.grafana_cloud_stack.graf_stack.org_id
  }
}

resource "grafana_cloud_access_policy_token" "alloy_token" {
  region           = grafana_cloud_access_policy.alloy_pol.region
  access_policy_id = grafana_cloud_access_policy.alloy_pol.policy_id
  name             = "alloy-token"
  display_name     = "Alloy token for Linux Server integration"
}

resource "hcp_vault_secrets_secret" "hcp_alloy_token" {
  app_name     = var.vault_secrets_app
  secret_name  = "GRAF_ALLOY_TOKEN"
  secret_value = grafana_cloud_access_policy_token.alloy_token.token
}