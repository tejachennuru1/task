resource "azurerm_resource_group" "tony" {
  name     = "task"
  location = "West Europe"
}
resource "azurerm_virtual_network" "VN" {
  name                = "VNet"
  location            = azurerm_resource_group.tony.location
  resource_group_name = azurerm_resource_group.tony.name
  address_space       = ["10.0.0.0/16"]
  depends_on = [
    azurerm_resource_group.tony
  ]
}
resource "azurerm_subnet" "subnet" {
  name                 = "sub"
  resource_group_name  = azurerm_resource_group.tony.name
  virtual_network_name = azurerm_virtual_network.VN.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.VN
  ]
}
resource "azurerm_public_ip" "pubip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.tony.name
  location            = azurerm_resource_group.tony.location
  allocation_method   = "Dynamic"
  }
resource "azurerm_network_interface" "main" {
  name                = "nic"
  location            = azurerm_resource_group.tony.location
  resource_group_name = azurerm_resource_group.tony.name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip.id
  }
  depends_on = [
    azurerm_subnet.subnet
  ]
}
resource "azurerm_linux_virtual_machine" "VM1" {
  name                            = "vm"
  resource_group_name             = azurerm_resource_group.tony.name
  location                        = azurerm_resource_group.tony.location
  size                            = "Standard_B1s"
  admin_username                  = "madhu"
  admin_password                  = "Adminadmin@123"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id
  ]
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
  }
resource "null_resource" "configure_identity" {
  triggers = {
    version = 2.0
  }
  provisioner "local-exec" {
    //command = "ls"
    command = "sshpass -pAdminadmin@123  ansible-playbook -u madhu -i ${azurerm_linux_virtual_machine.VM1.public_ip_address},playbook.yaml"
    //sshpass -p <ssh-password> ansible-playbook -u <username> --ask-pass playbooks/monitor-linux-node.yml
  }
  depends_on = [
    azurerm_linux_virtual_machine.VM1
  ]
}