resource "azurerm_network_interface" "at-win16326" {
	 name = "at-win16326"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 network_security_group_id = "${azurerm_network_security_group.at-win16-nsg.id}" 
	 ip_configuration {
		 name = "ipconfig1" 
		 subnet_id = "${azurerm_subnet.front.id}" 
		 private_ip_address_allocation = "Dynamic" 
		 public_ip_address_id = "${azurerm_public_ip.at-win16-ip.id}" 
	}
}
