variable "AWS_REGION" {    
    default = "eu-west-1"
}

variable "AMI" {
    type = map(string)

    default = {
        # For demo purposes only, we are using ubuntu for the web1 and db1 instances
        eu-west-1 = "ami-08ca3fed11864d6bb" # Ubuntu 20.04 x86
    }
}
variable "EC2_USER" {
    default = "ubuntu"
}
variable "PUBLIC_KEY_PATH" {
    default = "./public_key.pub" # Replace this with a path to your public key
}