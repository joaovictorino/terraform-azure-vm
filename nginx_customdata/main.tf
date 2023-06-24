provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-example" {
  name     = "rg-example"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet-example" {
  name                = "vnet-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg-example.location
  resource_group_name = azurerm_resource_group.rg-example.name
}

resource "azurerm_subnet" "sub-example" {
  name                 = "sub-example"
  resource_group_name  = azurerm_resource_group.rg-example.name
  virtual_network_name = azurerm_virtual_network.vnet-example.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "pip-example" {
  name                = "pip-example"
  location            = azurerm_resource_group.rg-example.location
  resource_group_name = azurerm_resource_group.rg-example.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg-example" {
  name                = "nsg-example"
  location            = azurerm_resource_group.rg-example.location
  resource_group_name = azurerm_resource_group.rg-example.name

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
  network_interface_id      = azurerm_network_interface.nic-example.id
  network_security_group_id = azurerm_network_security_group.nsg-example.id
}

resource "azurerm_network_interface" "nic-example" {
  name                = "nic-example"
  location            = azurerm_resource_group.rg-example.location
  resource_group_name = azurerm_resource_group.rg-example.name

  ip_configuration {
    name                          = "teste-ip-config"
    subnet_id                     = azurerm_subnet.sub-example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-example.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-example" {
  name                = "vm-example"
  location            = azurerm_resource_group.rg-example.location
  resource_group_name = azurerm_resource_group.rg-example.name
  size                = "Standard_DS1_v2"

  admin_username = "azureuser"
  admin_password = "Teste@admin123!"

  network_interface_ids = [azurerm_network_interface.nic-example.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  disable_password_authentication = false

  custom_data = base64encode(<<EOF
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "Teste 1234!" > /var/www/html/index.html
EOF
  )
}