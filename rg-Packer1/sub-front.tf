resource "azurerm_subnet" "front" {
	 name = "front"
	 virtual_network_name = "vnet-rh7-packer-at1"
	 address_prefix = "192.168.9.64/28"
	 resource_group_name = "${var.rgtarget}"
	 network_security_group_id = "${azurerm_network_security_group.nsg-atfront.id}"
}
