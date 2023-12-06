variable "region" {
    description = "AWS region"
    default     = "us-west-2"
}

variable "availability_zone" {
    description = "Availability zone"
    default     = "ap-south-1b"
}

variable "instance_count" {
    description = "Number of web server instances"
    default     = 2
}

variable "instance_type" {
    description = "Type of instance"
    default     = "t2.micro"
}

variable "ami" {
    default = "ami-0447a12f28fddb066"
}

variable "key_name" {
    default = "sshkey-m5"
}