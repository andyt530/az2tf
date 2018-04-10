resource "azurerm_resource_group" "NetworkWatcherRG" {
	 name = "NetworkWatcherRG"
	 location = "${var.loctarget}"
}
