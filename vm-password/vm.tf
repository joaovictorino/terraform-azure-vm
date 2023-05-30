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

resource "azurerm_resource_group" "myterraformgroup" {
  name     = "myterraformgroup"
  location = "eastus"

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_virtual_network" "myterraformvnet" {
  name                = "myterraformvnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    "aula" = "vm"
  }
}

resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "myterraformsubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformvnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "myterraformnsg"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

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

resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myterraformpublicip"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "myterraformnic" {
  name                = "myterraformnic"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "myNICConfg"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-aula-vm" {
  network_interface_id      = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

resource "azurerm_virtual_machine" "myterraformvm" {
  name                  = "myterraformvm"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.myterraformnic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDiskmyTFVM"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "myTFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

output "public_ip_address_vm" {
  value = azurerm_public_ip.myterraformpublicip.ip_address
}
