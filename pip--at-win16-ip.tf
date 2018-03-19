resource "azurerm_public_ip" "at-win16-ip" {
	 name = "at-win16-ip"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 public_ip_address_allocation = "Dynamic" 
}
