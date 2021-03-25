output "rdp" {
  description = "The password for RDP"
  value       = random_password.virtual_machine_admin_password.result
}

output "pip" {
  description = "The public IP address for the manager node"
  value       = azurerm_public_ip.swarm_manager_pip.ip_address
}