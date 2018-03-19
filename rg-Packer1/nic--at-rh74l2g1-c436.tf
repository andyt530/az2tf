resource "azurerm_network_interface" "at-rh74l2g1-c436" {
	 name = "at-rh74l2g1-c436"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 ip_configuration {
		 name = "ipconfig1" 
		 subnet_id = "${azurerm_subnet.front.id}" 
		 private_ip_address_allocation = "Dynamic" 
	}
}
