terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.58.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "rg-aulainfracloud" {
  name     = "aulainfracloudterraform"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet-aulainfra" {
  name                = "vnet-aula"
  location            = azurerm_resource_group.rg-aulainfracloud.location
  resource_group_name = azurerm_resource_group.rg-aulainfracloud.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
    faculdade   = "Impacta"
    turma       = "ES23"
  }
}

resource "azurerm_subnet" "sub-aulainfra" {
  name                 = "sub-aula"
  resource_group_name  = azurerm_resource_group.rg-aulainfracloud.name
  virtual_network_name = azurerm_virtual_network.vnet-aulainfra.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ip-aulainfra" {
  name                = "ip-aula"
  resource_group_name = azurerm_resource_group.rg-aulainfracloud.name
  location            = azurerm_resource_group.rg-aulainfracloud.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "nsg-aulainfra" {
  name                = "nsg-aula"
  location            = azurerm_resource_group.rg-aulainfracloud.location
  resource_group_name = azurerm_resource_group.rg-aulainfracloud.name

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

  security_rule {
    name                       = "web"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic-aulainfra" {
  name                = "nic-aula"
  location            = azurerm_resource_group.rg-aulainfracloud.location
  resource_group_name = azurerm_resource_group.rg-aulainfracloud.name

  ip_configuration {
    name                          = "ip-aula-nic"
    subnet_id                     = azurerm_subnet.sub-aulainfra.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-aulainfra.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-aulainfra" {
  network_interface_id      = azurerm_network_interface.nic-aulainfra.id
  network_security_group_id = azurerm_network_security_group.nsg-aulainfra.id
}

resource "azurerm_linux_virtual_machine" "vm-aulainfra" {
  name                  = "vm-aula"
  location              = azurerm_resource_group.rg-aulainfracloud.location
  resource_group_name   = azurerm_resource_group.rg-aulainfracloud.name
  network_interface_ids = [azurerm_network_interface.nic-aulainfra.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDiskMySQL"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "hostname"
  admin_username                  = var.user
  admin_password                  = var.pwd_user
  disable_password_authentication = false

  tags = {
    environment = "staging"
  }
}

resource "null_resource" "install-apache" {
  connection {
    type     = "ssh"
    host     = azurerm_public_ip.ip-aulainfra.ip_address
    user     = var.user
    password = var.pwd_user
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2",
    ]
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm-aulainfra
  ]
}

resource "null_resource" "upload-app" {
  connection {
    type     = "ssh"
    host     = azurerm_public_ip.ip-aulainfra.ip_address
    user     = var.user
    password = var.pwd_user
  }

  provisioner "file" {
    source      = "app"
    destination = "/home/testeadmin"
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm-aulainfra
  ]
}

output "public_ip_apache" {
  value = "http://${azurerm_public_ip.ip-aulainfra.ip_address}"
}
