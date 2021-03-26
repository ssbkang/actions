output "test-platform-output" {
  value = <<CONTENT

Windows
1. The public IP address for the manager node is ${azurerm_public_ip.swarm_manager_pip.ip_address}
2. The portainer image deployed is ${var.portainer_image}
3. Portainer can be accessed via ${azurerm_public_ip.swarm_manager_pip.ip_address}:9000
4. If RDP or SSH is required for management:
    RDP
      Endpoint: ${azurerm_public_ip.swarm_manager_pip.ip_address}:3389
      Username: local_admin
      Password: ${random_password.virtual_machine_admin_password.result}
    SSH
      Endpoint: ${azurerm_public_ip.swarm_manager_pip.ip_address}:22
      Username: local_admin
      Password: ${random_password.virtual_machine_admin_password.result}

  CONTENT
}