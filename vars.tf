variable "aws_region" {
  description = "AWS region to deploy your server in."
  type = string
  default = "your-preferred-aws-region" # Replace this value
}

variable "home_ip" {
  description = "The IP of your home router, used to ssh into the Palworld server"
  type = string
  default = "your-home-ip" # Replace this value
}

variable "ami_id" {
  description = "The ami ID you want to deploy the sever with."
  type = string
  default = "your-ami-id" # Replace this value
}