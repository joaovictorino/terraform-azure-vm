terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

  required_version = ">= 0.13"
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "rg-aula-vm" {
  name     = "rg-aula-vm"
  location = "eastus"

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_virtual_network" "vnet-aula-vm" {
  name                = "vnet-aula-vm"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-aula-vm.name

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_subnet" "sub-aula-vm" {
  name                 = "sub-aula-vm"
  resource_group_name  = azurerm_resource_group.rg-aula-vm.name
  virtual_network_name = azurerm_virtual_network.vnet-aula-vm.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip-aula-vm" {
  name                = "pip-aula-vm"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-aula-vm.name
  allocation_method   = "Static"

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_network_security_group" "nsg-aula-vm" {
  name                = "nsg-aula-vm"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-aula-vm.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_network_interface" "nic-aula-vm" {
  name                = "nic-aula-vm"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg-aula-vm.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.sub-aula-vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-aula-vm.id
  }

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-aula-vm" {
  network_interface_id      = azurerm_network_interface.nic-aula-vm.id
  network_security_group_id = azurerm_network_security_group.nsg-aula-vm.id
}

resource "tls_private_key" "ssh-aula-vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh-aula-vm.private_key_pem
  filename        = "key.pem"
  file_permission = "0600"
}

resource "azurerm_linux_virtual_machine" "vm-aula-vm" {
  name                  = "vm-aula-vm"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.rg-aula-vm.name
  network_interface_ids = [azurerm_network_interface.nic-aula-vm.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "myvm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh-aula-vm.public_key_openssh
  }

  tags = {
    "aula" = "vm"
  }
}

output "public_ip_address" {
  value = azurerm_public_ip.pip-aula-vm.ip_address
}
