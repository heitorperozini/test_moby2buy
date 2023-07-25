terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  features {}
}

################################################################################
# RESOURCE GROUP
###############################################################################

resource "azurerm_resource_group" "test" {
  name     = "rg-test"
  location = var.location
}

################################################################################
# NETWORK
###############################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "public" {
  name                 = "subnet-public"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


################################################################################
# BASTION VM
###############################################################################


resource "azurerm_linux_virtual_machine" "bastion_vm" {
  name                  = "bastion-vm"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  size                  = "Standard_DS2_v2"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.bastion_nic.id]

  admin_ssh_key {
   username = "azureuser"
   public_key = data.azurerm_ssh_public_key.bastion.id

}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "bastion-public-ip"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  domain_name_label   = "bastion"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion_nic" {
  name                      = "bastion-nic"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "bastion_nic_sga" {
  network_interface_id      = azurerm_network_interface.bastion_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  }

resource "azurerm_network_security_group" "nsg" {
  name                = "bastion-nsg"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

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
}

resource "azurerm_ssh_public_key" "bastion" {
  name                = "bastion_key"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  generate_key        = true
}

################################################################################
# APP VM
###############################################################################
data "template_file" "nginx-vm-cloud-init" {
  template = file("install-nginx.sh")
}
resource "azurerm_linux_virtual_machine" "nginx_vm" {
  name                  = "nginx-vm"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  size                  = "Standard_DS2_v2"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nginx_nic.id]
    custom_data = base64encode(data.template_file.nginx-vm-cloud-init.rendered)

  admin_ssh_key {
   username = "azureuser"
   public_key = data.azurerm_ssh_public_key.app.id
}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  domain_name_label   = "app"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nginx_nic" {
  name                      = "nginx-nic"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.app_public_ip.id
  }
}

resource "azurerm_network_security_group" "nsg_app" {
  name                = "app-nsg"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_network_security_group" "nsg_nginx" {
  name                = "nginx-nsg"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_network_security_rule" "nsg_app_ssh" {
  name                        = "allow-ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = azurerm_network_interface.nginx_nic.private_ip_address
  network_security_group_name = azurerm_network_security_group.nsg_app.name
}

resource "azurerm_network_interface_security_group_association" "nginx_nic_sga" {
  network_interface_id      = azurerm_network_interface.nginx_nic.id
  network_security_group_id = azurerm_network_security_group.nsg_nginx.id
}

resource "azurerm_ssh_public_key" "app" {
  name                = "app_key"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  generate_key        = true
}

################################################################################
# CONTAINER REGISTRY
###############################################################################

resource "azurerm_container_registry" "acr" {
  name                = "testcontainerregistry"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  sku                 = "Basic"
}