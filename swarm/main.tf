terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      version = "=2.50.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  ## DO NOT TOUCH
  prefix                                = "test-${var.pr_or_branch}"
  resource_group_name                   = "${local.prefix}-rg"
  virtual_network_name                  = "${local.prefix}-vnet"
  virtual_network_cidr                  = "10.0.0.0/23"
  network_security_group_name           = "${local.prefix}-nsg"
  subnet_name                           = "${var.pr_or_branch}Subnet"
  subnet_address_prefix                 = "10.0.1.0/24"
  availability_set_name                 = "${local.prefix}-as"
  virtual_machine_admin_name            = "local_admin"
  virtual_machine_sku                   = "Standard_D2s_v4"
  virtual_machine_os_publisher          = "MicrosoftWindowsServer"
  virtual_machine_os_offer              = "WindowsServer"
  virtual_machine_os_sku                = "2019-datacenter-core-with-containers-g2"
  # virtual_machine_os_sku                = "2019-datacenter-with-containers-g2"
  virtual_machine_os_version            = "latest"
  virtual_machine_worker_scale_set_name = "${local.prefix}-win-wkr-vmss"

  tags = {
    environment  = "test"
    application  = "portainer"
    pr_or_branch = var.pr_or_branch
    owner        = var.owner
    location     = var.location
  }
}

resource "azurerm_resource_group" "swarm_resource_group" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "swarm_virtual_network" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.swarm_resource_group.location
  resource_group_name = azurerm_resource_group.swarm_resource_group.name
  address_space = [
    local.virtual_network_cidr
  ]

  tags = local.tags
}

resource "azurerm_subnet" "swarm_subnet" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.swarm_resource_group.name
  virtual_network_name = azurerm_virtual_network.swarm_virtual_network.name
  address_prefixes = [
    local.subnet_address_prefix
  ]
}

resource "azurerm_network_security_group" "swarm_subnet_network_security_group" {
  name                = local.network_security_group_name
  location            = azurerm_resource_group.swarm_resource_group.location
  resource_group_name = azurerm_resource_group.swarm_resource_group.name

  security_rule {
    name              = "allow-inbound-testing"
    priority          = 100
    direction         = "Inbound"
    access            = "Allow"
    protocol          = "Tcp"
    source_port_range = "*"
    destination_port_ranges = [
      3389,
      22,
      9000,
      800
    ]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "swarm_subnet_network_security_group_association" {
  subnet_id                 = azurerm_subnet.swarm_subnet.id
  network_security_group_id = azurerm_network_security_group.swarm_subnet_network_security_group.id
}

resource "azurerm_public_ip" "swarm_manager_pip" {
  name                = "${local.prefix}-win-mgr-vm1-pip1"
  location            = azurerm_resource_group.swarm_resource_group.location
  resource_group_name = azurerm_resource_group.swarm_resource_group.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "swarm_manager_virtual_machine_network_interface" {
  name                = "${local.prefix}-win-mgr-vm1-nic"
  location            = azurerm_resource_group.swarm_resource_group.location
  resource_group_name = azurerm_resource_group.swarm_resource_group.name

  tags = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.swarm_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.11"
    public_ip_address_id          = azurerm_public_ip.swarm_manager_pip.id
  }
}

resource "random_password" "virtual_machine_admin_password" {
  length  = 40
  special = true
}

resource "azurerm_windows_virtual_machine" "swarm_manager_virtual_machine" {
  name                = "${local.prefix}-win-mgr-vm1"
  location            = azurerm_resource_group.swarm_resource_group.location
  resource_group_name = azurerm_resource_group.swarm_resource_group.name
  size                = local.virtual_machine_sku
  admin_username      = local.virtual_machine_admin_name
  admin_password      = random_password.virtual_machine_admin_password.result

  network_interface_ids = [
    azurerm_network_interface.swarm_manager_virtual_machine_network_interface.id,
  ]

  computer_name = "swarm-vm1"

  os_disk {
    name                 = "${local.prefix}-win-mgr-vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = local.virtual_machine_os_publisher
    offer     = local.virtual_machine_os_offer
    sku       = local.virtual_machine_os_sku
    version   = local.virtual_machine_os_version
  }

  allow_extension_operations = true

  tags = local.tags
}

resource "azurerm_virtual_machine_extension" "swarm_manager_init" {
  name                 = "init-swarm-manager"
  virtual_machine_id   = azurerm_windows_virtual_machine.swarm_manager_virtual_machine.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    "fileUris" = [
      "https://raw.githubusercontent.com/ssbkang/scripts/main/windows/init-manager.ps1"
    ]
  })

  protected_settings = jsonencode({
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File init-manager.ps1 -portainer_image ${var.portainer_image}"
  })

  tags = local.tags
}
