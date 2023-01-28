
variable "project_tags" {
  type        = map(string)
  default = {
    project = "aws-exercise"
  }
}

variable "ports" {
  type    = map(number)
  default = {
    http  = 80
    https = 22
  }
}