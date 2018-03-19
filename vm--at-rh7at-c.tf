resource "azurerm_virtual_machine" "at-rh7at-c" {
	 name = "at-rh7at-c"
	 location = "${var.loctarget}"
	 resource_group_name = "${var.rgtarget}"
	 vm_size = "Standard_B2s"
	 network_interface_ids = ["/subscriptions/304e776d-6a37-425c-9304-cd3a77e4c6fe/resourceGroups/rg-Packer1/providers/Microsoft.Network/networkInterfaces/at-rh7at-c415"]
	 delete_data_disks_on_termination = "true"
	 delete_os_disk_on_termination = "true"
os_profile {
	computer_name = "at-rh7at-c" 
	admin_username = "thomasa" 
}
storage_os_disk {
	name = "at-rh7at-c_disk1_6e2ab2ca09b54adbb188b976737a9369" 
	caching = "None" 
	managed_disk_type = "Premium_LRS" 
	create_option = "FromImage" 
	os_type = "Linux" 
}
boot_diagnostics {
	 enabled = "true"
	 storage_uri = "https://diagcdsdevrh7.blob.core.windows.net/"
}
os_profile_linux_config {
	disable_password_authentication = "true" 
	ssh_keys {
		path = "/home/thomasa/.ssh/authorized_keys" 
		key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCX13egiVvIQ+VxHE+0LLBkqFqnvrKcFijGz+rq3q/BzwIT/nhZe0y8H94UNLS0TeTGNec5mCXq91WKDkpWkQ7WFimoggUAzJTH1RyuPmaUbkv0ZvBrJksEHea3TZIRXD744cWMYcUsrcAc/88Um4/pi3aL0Etv/zkjKBY4hqzAxHqVivbXqa0dykp49Z7OZ9Hu+ncIH87TmuWwwlzifYNQ7hMEvQZnxam2k06mMLGBj6fT4Qb36I9cl6H4XUAGeJrjZDj4+iDfZ/j+U0cRBU1KnOKTgwKXiU8Sk7rH5NLR2mzi4nu5b5bthA//o8mnb4IoIN4o6dgCrJKR5Z/4nF4j"
	}
}
}
