output "instance_ocid" {
  value = oci_core_instance.vm.id
}

output "public_ip" {
  value = data.oci_core_vnic.vnic.public_ip_address
}

output "ssh_command" {
  value = "ssh ubuntu@${data.oci_core_vnic.vnic.public_ip_address}"
}

output "image_ocid_in_use" {
  value = var.image_ocid != "" ? var.image_ocid : data.oci_core_images.ubuntu.images[0].id
}
