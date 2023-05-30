variable "admin_username" {
    type = string
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type = string
    description = "Password must meet Azure complexity requirements"
}

resource "azurerm_public_ip" "publicip" {
  name                = "myTFPublicIP"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                      = "myNICVM2"
  location                  = "eastus"
  resource_group_name       = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "myNICConfg"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "myTFVM"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.nic.id]
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

output "public_ip_address_vm2" {
  value = azurerm_public_ip.publicip.ip_address
}