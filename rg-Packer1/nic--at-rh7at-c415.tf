resource "azurerm_network_interface" "at-rh7at-c415" {
	 name = "at-rh7at-c415"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 ip_configuration {
		 name = "ipconfig1" 
		 subnet_id = "${azurerm_subnet.front.id}" 
		 private_ip_address_allocation = "Dynamic" 
	}
}
