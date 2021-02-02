

resource "random_string" "random" {
  length = 16
  special = true
  override_special = "/@£$"
}



data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "as_conf" {
  name          = "web_config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}


resource "aws_autoscaling_group" "bar" {
  name                      = "shane1"
  max_size                  = 1
  min_size                  = 0
  health_check_grace_period = 300
  force_delete              = true
  vpc_zone_identifier       = ["subnet-0b64c3204be4d14c1"]
  launch_configuration = aws_launch_configuration.as_conf.name
  tags = [
      {
        "key"                 = "Name"
        "value"               = random_string.random.result
        "propagate_at_launch" = "true"
      },
      {
        "key"                 = "kubernetes.io/cluster/fixed"
        "value"               = random_string.random.result
        "propagate_at_launch" = "true"
      }
  ]

}
