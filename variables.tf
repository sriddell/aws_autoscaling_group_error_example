variable "cluster_name" {
    default = "shane"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {
      "foo": "bar",
      "bar": "baz"
  }
}

variable "node_group" {
  type        = any
}

variable "workers_group_defaults" {
  description = "Override default values for target groups. See workers_group_defaults_defaults in local.tf for valid keys."
  type        = any
  default     = {}
}