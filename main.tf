provider "alicloud" {
  profile                 = var.profile != "" ? var.profile : null
  shared_credentials_file = var.shared_credentials_file != "" ? var.shared_credentials_file : null
  region                  = var.region != "" ? var.region : null
  skip_region_validation  = var.skip_region_validation
  configuration_source    = "terraform-alicloud-modules/lnmp"
}
data "alicloud_images" "centos" {
  most_recent = true
  name_regex  = "centos_7"
}
# Create an ECS Instance to deploy lnmp
module "ecs-instance" {
  source                  = "alibaba/ecs-instance/alicloud"
  profile                 = var.profile != "" ? var.profile : null
  shared_credentials_file = var.shared_credentials_file != "" ? var.shared_credentials_file : null
  region                  = var.region != "" ? var.region : null
  skip_region_validation  = var.skip_region_validation


  number_of_instances = var.number_of_instances
  use_num_suffix      = var.use_num_suffix

  instance_name = var.instance_name
  password      = var.instance_password
  image_id      = var.image_id != "" ? var.image_id : data.alicloud_images.centos.ids.0
  instance_type = var.instance_type

  instance_charge_type = "PostPaid"
  system_disk_category = var.system_disk_category
  system_disk_size     = var.system_disk_size

  security_group_ids = var.security_group_ids
  vswitch_ids        = [var.vswitch_id]
  private_ips        = [var.private_ip]

  internet_charge_type        = var.internet_charge_type
  associate_public_ip_address = true
  internet_max_bandwidth_out  = var.internet_max_bandwidth_out

  resource_group_id   = var.resource_group_id
  deletion_protection = var.deletion_protection
  force_delete        = true
  tags = merge(
    {
      Created     = "Terraform"
      Application = "LNMP"
    }, var.tags,
  )

  data_disks  = var.data_disks
  volume_tags = var.volume_tags
  user_data   = data.template_file.shell.rendered
}

data "template_file" "shell" {
  template = file("userdata.sh")

  vars = {
    db_name     = var.db_name
    db_user     = var.db_user
    db_pwd      = var.db_password
    db_root_pwd = var.db_root_password
  }
}
