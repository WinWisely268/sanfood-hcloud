source "hcloud" "main" {
  token = var.hcloud_api_token

  image = "ubuntu-20.04"
  server_name = "sanfood-{{timestamp}}"
  server_type = "cx11"
  location = "nbg1"

  snapshot_name = "sanfood-{{timestamp}}"
  snapshot_labels = {
    service = "sanfood-hasura"
  }

  user_data_file = "./hetzner/cloud-config"

  ssh_port = "22"
  ssh_username = "root"
  ssh_timeout = "10m"
  ssh_clear_authorized_keys = true
}