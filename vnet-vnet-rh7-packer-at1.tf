resource azurerm_virtual_network "vnet-rh7-packer-at1" {
	name = "vnet-rh7-packer-at1"
	location = "uksouth"
	resource_group_name = "rg-Packer1"
	address_space = ["192.168.9.64/26"]
	subnet {
		 name = "front"
		 address_prefix = "192.168.9.64/28"
		 security_group = "${azurerm_network_security_group.nsg-atfront.id}"
	}
}
