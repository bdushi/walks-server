locals {
  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    install_java               = var.install_java
    install_host_nginx_certbot = var.install_host_nginx_certbot
    domain                     = var.domain
  })
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.shape

  # Most recent first
  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_display_name}-vcn"
  cidr_block     = var.vcn_cidr
  dns_label      = "walksvcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_display_name}-igw"
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = true
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.instance_display_name}-public-rt"

  route_rules {
    description       = "Default route to internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.instance_display_name}-public-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.instance_display_name}-public-subnet"
  cidr_block     = var.subnet_cidr
  dns_label      = "pub1"

  route_table_id = oci_core_route_table.public_rt.id
  security_list_ids = [
    oci_core_security_list.public_sl.id
  ]

  prohibit_public_ip_on_vnic = false
}

resource "oci_core_instance" "vm" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = var.instance_display_name

  shape = var.shape
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = var.image_ocid != "" ? var.image_ocid : data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }
}

data "oci_core_vnic_attachments" "va" {
  compartment_id      = var.compartment_ocid
  availability_domain = oci_core_instance.vm.availability_domain
  instance_id         = oci_core_instance.vm.id
}

data "oci_core_vnic" "vnic" {
  vnic_id = data.oci_core_vnic_attachments.va.vnic_attachments[0].vnic_id
}
