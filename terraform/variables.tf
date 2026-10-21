variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "ap-southeast-2" # Sydney
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "repo_url" {
  description = "Public GitHub repo containing the Dockerfile"
  type        = string
  default     = "https://github.com/deep5679/Visionassist.git"
}
