### Default Region ###
variable "region" {
  description = "AWS Region"
  default = "us-east-1"
}


### SSH public key path ###
variable "key_path" {
  description = "Public key path"
  default = "/home/ca/.ssh/id_rsa.pub" //edit here
}


### Linux AMI type for EC2 machine ###
variable "ami" {
  description = "AMI"
  default = "ami-8c1be5f6" // Amazon Linux
}


### Instance class ###
variable "instance_type" {
  description = "EC2 instance type"
  default = "t2.micro"
}


### Amazon Virtual Private Cloud for the project ###
variable "vpc_id" {
  description = "vpc-29368153"
  default = "vpc-29368153" //edit here
}


### s3 bucket where the spring boot project should be ###
variable "s3_bucket" {
  description = "project-springbot"
  default = "project-springbot" //edit here
}


