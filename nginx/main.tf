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
  }
}

resource "azurerm_resource_group" "as04infra" {
  name     = "as04infra"
  location = "eastus"
}

resource "azurerm_resource_group" "teste-importacao" {
  name     = "teste-importacao"
  location = "westus2"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.as04infra.location
  resource_group_name = azurerm_resource_group.as04infra.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.as04infra.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "publicip"
  resource_group_name = azurerm_resource_group.as04infra.name
  location            = azurerm_resource_group.as04infra.location
  allocation_method   = "Static"

  tags = {
    turma      = "as04"
    disciplina = "infra cloud"
    professor  = "João"
  }
}

resource "azurerm_network_interface" "as04-nic" {
  name                = "as04-nic"
  location            = azurerm_resource_group.as04infra.location
  resource_group_name = azurerm_resource_group.as04infra.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_security_group" "infra-ng" {
  name                = "infra-ng"
  location            = azurerm_resource_group.as04infra.location
  resource_group_name = azurerm_resource_group.as04infra.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Web"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "ng-nic-assoc" {
  network_interface_id      = azurerm_network_interface.as04-nic.id
  network_security_group_id = azurerm_network_security_group.infra-ng.id
}

resource "tls_private_key" "private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.private-key.private_key_pem
  filename        = "key.pem"
  file_permission = "0600"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm"
  resource_group_name = azurerm_resource_group.as04infra.name
  location            = azurerm_resource_group.as04infra.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.as04-nic.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.private-key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  depends_on = [
    local_file.private_key
  ]
}

resource "null_resource" "install-nginx" {
  triggers = {
    order = azurerm_linux_virtual_machine.vm.id
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.publicip.ip_address
    user        = "adminuser"
    private_key = tls_private_key.private-key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx"
    ]
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]
}

output "public_ip_nginx" {
  value = "http://${azurerm_public_ip.publicip.ip_address}"
}
