variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  default     = "ami-0e872aee57663ae2d" # Replace with your AMI ID
}

variable "instance_type" {
  default = "m4.large"
  #default = "c5.4xlarge"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  default     = "raf" # Replace with your key pair name
}

variable "spot_price" {
  description = "The maximum price you're willing to pay for the spot instance"
  default     = "0.045200" # Updated to lowest spot price
}

variable "availability_zone" {
  description = "AZ where spot price is the lowest"
  default     = "eu-central-1b" # Updated to lowest AZ
}
