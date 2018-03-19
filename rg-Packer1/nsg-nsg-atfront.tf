resource "azurerm_network_security_group" "nsg-atfront" { 
	 name = "nsg-atfront"  
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
}
