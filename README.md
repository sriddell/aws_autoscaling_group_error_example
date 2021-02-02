Examples of a bug in aws terraform provider.

Terraform version 0.14.5

aws provider version 3.26.0

Summary: when the tags attribule has two or more tags with values that are not known until apply time, the plan emits a tags array of length 1.  When the plan is applied, this expands to an array of length 2, which terraform core treats as an inconsistent plan (that a list or set value should never increase in size) per assertValueCompatible function in compatible.go from terraform (core) 0.14.5.

This also holds true at least under 0.13.5 of terraform as well.


To replicate:

chdir to the error_example directory and:

terraform plan -out plan
You will get a plan like

```
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_autoscaling_group.bar will be created
  + resource "aws_autoscaling_group" "bar" {
      + arn                       = (known after apply)
      + availability_zones        = (known after apply)
      + default_cooldown          = (known after apply)
      + desired_capacity          = (known after apply)
      + force_delete              = true
      + health_check_grace_period = 300
      + health_check_type         = (known after apply)
      + id                        = (known after apply)
      + launch_configuration      = "web_config"
      + max_size                  = 1
      + metrics_granularity       = "1Minute"
      + min_size                  = 0
      + name                      = "shane1"
      + protect_from_scale_in     = false
      + service_linked_role_arn   = (known after apply)
      + tags                      = [
          + (known after apply),
        ]
      + vpc_zone_identifier       = [
          + "subnet-0b64c3204be4d14c1",
        ]
      + wait_for_capacity_timeout = "10m"
    }

  # aws_launch_configuration.as_conf will be created
  + resource "aws_launch_configuration" "as_conf" {
      + arn                         = (known after apply)
      + associate_public_ip_address = false
      + ebs_optimized               = (known after apply)
      + enable_monitoring           = true
      + id                          = (known after apply)
      + image_id                    = "ami-03d315ad33b9d49c4"
      + instance_type               = "t2.micro"
      + key_name                    = (known after apply)
      + name                        = "web_config"

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + no_device             = (known after apply)
          + snapshot_id           = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # random_string.random will be created
  + resource "random_string" "random" {
      + id               = (known after apply)
      + length           = 16
      + lower            = true
      + min_lower        = 0
      + min_numeric      = 0
      + min_special      = 0
      + min_upper        = 0
      + number           = true
      + override_special = "/@£$"
      + result           = (known after apply)
      + special          = true
      + upper            = true
    }

Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: plan

To perform exactly these actions, run the following command to apply:
    terraform apply "plan"
```

Note that the tags on the autoscaling group is a length 1 list:

```
      + tags                      = [
          + (known after apply),
        ]
```

This is what results from having 2 tags with a value unknown until apply on the autoscaling group:

```
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
      },
  ]
```

A "terraform apply plan" then results in:

```
random_string.random: Creating...
random_string.random: Creation complete after 0s [id=$rLVPTCr8N/pxfMM]
aws_launch_configuration.as_conf: Creating...
aws_launch_configuration.as_conf: Creation complete after 1s [id=web_config]

Error: Provider produced inconsistent final plan

When expanding the plan for aws_autoscaling_group.bar to include new values
learned so far during apply, provider "registry.terraform.io/hashicorp/aws"
produced an invalid new value for .tags: length changed from 1 to 2.

This is a bug in the provider, which should be reported in the provider's own
issue tracker.
```

In the working_example directory, everything is the same, except only one tag has a value unspecified until apply:

```
  tags = [
      {
        "key"                 = "Name"
        "value"               = random_string.random.result
        "propagate_at_launch" = "true"
      },
      {
        "key"                 = "kubernetes.io/cluster/fixed"
        "value"               = "known value"
        "propagate_at_launch" = "true"
      },
  ]
```

Here, "terraform plan -out plan" will produce a tags list of length 2, and the plan will apply without error:

```An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_autoscaling_group.bar will be created
  + resource "aws_autoscaling_group" "bar" {
      + arn                       = (known after apply)
      + availability_zones        = (known after apply)
      + default_cooldown          = (known after apply)
      + desired_capacity          = (known after apply)
      + force_delete              = true
      + health_check_grace_period = 300
      + health_check_type         = (known after apply)
      + id                        = (known after apply)
      + launch_configuration      = "web_config"
      + max_size                  = 1
      + metrics_granularity       = "1Minute"
      + min_size                  = 0
      + name                      = "shane1"
      + protect_from_scale_in     = false
      + service_linked_role_arn   = (known after apply)
      + tags                      = [
          + {
              + "key"                 = "kubernetes.io/cluster/fixed"
              + "propagate_at_launch" = "true"
              + "value"               = "known value"
            },
          + (known after apply),
        ]
      + vpc_zone_identifier       = [
          + "subnet-0b64c3204be4d14c1",
        ]
      + wait_for_capacity_timeout = "10m"
    }

  # aws_launch_configuration.as_conf will be created
  + resource "aws_launch_configuration" "as_conf" {
      + arn                         = (known after apply)
      + associate_public_ip_address = false
      + ebs_optimized               = (known after apply)
      + enable_monitoring           = true
      + id                          = (known after apply)
      + image_id                    = "ami-03d315ad33b9d49c4"
      + instance_type               = "t2.micro"
      + key_name                    = (known after apply)
      + name                        = "web_config"

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + no_device             = (known after apply)
          + snapshot_id           = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # random_string.random will be created
  + resource "random_string" "random" {
      + id               = (known after apply)
      + length           = 16
      + lower            = true
      + min_lower        = 0
      + min_numeric      = 0
      + min_special      = 0
      + min_upper        = 0
      + number           = true
      + override_special = "/@£$"
      + result           = (known after apply)
      + special          = true
      + upper            = true
    }

Plan: 3 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: plan

To perform exactly these actions, run the following command to apply:
    terraform apply "plan"
```


Note that if you change the error example two two unspecified values until apply time, and one fixed, it still fails: you get a tags list of length 2.  It appears that if any part of an element in tags for aws_autoscaling_group is unspecified until apply time, all such tag elements are collapsed into a single 'placeholder', resulting in a tags list that is smaller in the plan than it will be when applied, instead of inserting an unspecified value into the tags list for each tag w/ an unspecified key or value at plan time.

