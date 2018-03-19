resource "azurerm_virtual_machine" "at-win16" {
	 name = "at-win16"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 vm_size = "Standard_B2s"
	 network_interface_ids = ["/subscriptions/304e776d-6a37-425c-9304-cd3a77e4c6fe/resourceGroups/rg-Packer1/providers/Microsoft.Network/networkInterfaces/at-win16326"]
	 delete_data_disks_on_termination = "true"
	 delete_os_disk_on_termination = "true"
os_profile {
	computer_name = "at-win16" 
	admin_username = "thomasa" 
}
storage_os_disk {
	name = "at-win16_OsDisk_1_dc6fee9104b246eb90ec78c9c478d0b4" 
	caching = "ReadWrite" 
	managed_disk_type = "Premium_LRS" 
	create_option = "FromImage" 
}
boot_diagnostics {
	 enabled = "true"
	 storage_uri = "https://diagcdsdevrh7.blob.core.windows.net/"
}
}
