variable "cidr" {
  default = "10.0.0.0/16"
}

variable "sub1_cidr" {
  default = "121.12.1.0/24"
}

variable "sub2_cidr" {
  default = "121.12.2.0/24"
}

variable "ami_id" {
  default = "ami-02dfbd4ff395f2a1b"
}

variable "insatance_type" {
  default = "t3.micro"
}