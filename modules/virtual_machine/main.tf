data "azurerm_key_vault" "key_vault" {
  name                = var.vault_name
  resource_group_name = var.kv_resource_group_name
}

data "azurerm_key_vault_secret" "vmpassword" {
  name = "vmPassword"
  key_vault_id = data.azurerm_key_vault.key_vault.id 
}

resource "azurerm_network_security_group" "virtual_machine_nsg" {
    name                = "myNetworkSecurityGroup"
   location            = var.resource_location
   resource_group_name = var.resource_group_name
    
    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "networkinterface" {
  name                = var.network_interface_name
  location            = var.resource_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration01"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_nic" {
    network_interface_id      = azurerm_network_interface.networkinterface.id
    network_security_group_id = azurerm_network_security_group.virtual_machine_nsg.id
}

resource "azurerm_public_ip" "vm_public_ip" {
    name                         = "publicIpVm"
    location            = var.resource_location
    resource_group_name = var.resource_group_name
    allocation_method            = "Dynamic"
}

resource "azurerm_virtual_machine" "virtual_machine" {
  name                  = var.virtual_machine_name
  location              = var.resource_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.networkinterface.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

   storage_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.username
    admin_password = data.azurerm_key_vault_secret.vmpassword.value
  }
  
  os_profile_windows_config {
  }
}