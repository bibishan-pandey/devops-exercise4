# Specifies the required provider, in this case, the Azure Resource Manager (azurerm) provider.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

# Configures the Azure provider using environment variables for authentication.
provider "azurerm" {
  features {}

  client_id       = var.ARM_CLIENT_ID       # Azure Client ID from environment variables or passed in variable.
  client_secret   = var.ARM_CLIENT_SECRET   # Azure Client Secret for authentication.
  tenant_id       = var.ARM_TENANT_ID       # Azure Active Directory Tenant ID.
  subscription_id = var.ARM_SUBSCRIPTION_ID # Azure Subscription ID.
}

# Creates an Azure Resource Group in the Canada Central region.
resource "azurerm_resource_group" "rg" {
  name     = "nodeapp-rg"     # Name of the resource group.
  location = "Canada Central" # Region where the resource group will be created.
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "nodeapp-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "nodeapp-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "nodeapp-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  sku = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "nodeapp-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nodeapp-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "nsg-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Jenkins traffic
  security_rule {
    name                       = "allow-jenkins"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Node App traffic
  security_rule {
    name                       = "allow-nodeapp"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8000"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SonarQube traffic
  security_rule {
    name                       = "allow-sonarqube"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Nexus traffic
  security_rule {
    name                       = "allow-nexus"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group Association
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "nodeapp-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  # size                = "Standard_B1s"

  admin_username                  = "azureuser"
  admin_password                  = "d3v$0p$2024"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

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

  connection {
    host     = self.public_ip_address
    user     = self.admin_username
    password = self.admin_password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y curl git",

      "sudo apt-get install docker.io -y",
      "sudo gpasswd -a $USER docker",
      "sudo systemctl restart docker",

      "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "docker-compose --version",

      # Clone the Git repository using HTTPS with a token
      "git clone https://${var.GIT_USERNAME}:${var.GIT_TOKEN}@github.com/bibishan-pandey/devops-exercise4.git /home/azureuser/devops-exercise4",

      # Change to the directory and run docker-compose
      "cd /home/azureuser/devops-exercise4 && sudo docker-compose up -d"
    ]
  }
}



# # Creates an Azure Kubernetes Service (AKS) cluster within the resource group.
# resource "azurerm_kubernetes_cluster" "aks_cluster" {
#   name                = "azure-devops-aks-cluster"                     # Name of the AKS cluster.
#   location            = azurerm_resource_group.resource_group.location # Location is set to match the resource group.
#   resource_group_name = azurerm_resource_group.resource_group.name     # Associates the cluster with the resource group.
#   dns_prefix          = "azure-devops-aks-cluster-dns"                 # DNS prefix for the cluster.

#   # Configures the default node pool for the AKS cluster.
#   default_node_pool {
#     name                 = "clusterpool"   # Name of the node pool.
#     vm_size              = "Standard_B2ms" # Specifies the virtual machine size for the nodes.
#     auto_scaling_enabled = true            # Enables auto-scaling for the node pool.
#     # node_count          = 2                       # Initial number of nodes.
#     min_count = 1 # Minimum number of nodes when scaling down.
#     max_count = 3 # Maximum number of nodes when scaling up.
#   }

#   # Enables system-assigned managed identity for the AKS cluster.
#   identity {
#     type = "SystemAssigned"
#   }
# }

# # Outputs the Kubernetes configuration (kubeconfig) for accessing the AKS cluster.
# output "kube_config" {
#   value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw # Raw kubeconfig value.
#   sensitive = true                                                   # Marks the output as sensitive to prevent it from being displayed in plain text.
# }
