resource "azurerm_network_security_group" "at-win16-nsg" { 
	 name = "at-win16-nsg"  
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
}
