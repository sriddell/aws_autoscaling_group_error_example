resource "random_string" "random" {
  length = 16
  special = true
  override_special = "/@£$"
}

locals {
  workers_group_defaults_defaults = {
    tags                          = []
  }
  asg_tags = [
    for item in keys(var.tags) :
    map(
      "key", item,
      "value", element(values(var.tags), index(keys(var.tags), item)),
      "propagate_at_launch", "true"
    )
  ]
  workers_group_defaults = merge(
    local.workers_group_defaults_defaults,
    var.workers_group_defaults,
  )
}

resource "aws_autoscaling_group" "bar" {
  name                      = "shane1"
  max_size                  = 1
  min_size                  = 0
  health_check_grace_period = 300
  force_delete              = true
  vpc_zone_identifier       = ["subnet-0b64c3204be4d14c1"]
  launch_configuration = "shaneCopy"
  tags = concat(
    [
      {
        "key"                 = "Name"
        "value"               = "${var.cluster_name}-${random_string.random.result}"
        "propagate_at_launch" = "true"
      },
      {
        "key"                 = "kubernetes.io/cluster/${random_string.random.result}"
        "value"               = "owned"
        "propagate_at_launch" = "true"
      },
    ],
    local.asg_tags,
    lookup(
      var.node_group,
      "tags",
      local.workers_group_defaults["tags"]
    )
  )
}