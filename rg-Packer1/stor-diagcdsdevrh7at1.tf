resource "azurerm_storage_account" "diagcdsdevrh7at1" {
	 name = "diagcdsdevrh7at1"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 account_tier = "Standard"
	 account_replication_type = "LRS"
	 enable_blob_encryption = "true"
	 enable_https_traffic_only = "false"
}
