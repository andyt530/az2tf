resource "azurerm_storage_account" "diagcdsdevrh7" {
	 name = "diagcdsdevrh7"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 account_tier = "Standard"
	 account_replication_type = "LRS"
	 enable_blob_encryption = "true"
	 enable_https_traffic_only = "false"
}
