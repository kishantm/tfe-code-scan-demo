provider "aws" {
    region = "${var.AWS_REGION}"
}

module "database"{
    source="./modules/db"
}

resource "aws_instance" "web1" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t2.micro"

    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    # vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]

    tags = {
        Name: "My VPC Demo 2"
    }
}

# Add internet gateway
resource "aws_internet_gateway" "prod-igw" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    tags = {
        Name = "prod-igw"
    }
}

# Public routes
resource "aws_route_table" "prod-public-crt" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = "${aws_internet_gateway.prod-igw.id}" 
    }
    
    tags = {
        Name = "prod-public-crt"
    }
}
resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"
    route_table_id = "${aws_route_table.prod-public-crt.id}"
}

# Private routes
resource "aws_route_table" "prod-private-crt" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.prod-nat-gateway.id}" 
    }
    
    tags = {
        Name = "prod-private-crt"
    }
}
resource "aws_route_table_association" "prod-crta-private-subnet-1"{
    subnet_id = "${aws_subnet.prod-subnet-private-1.id}"
    route_table_id = "${aws_route_table.prod-private-crt.id}"
}

# NAT Gateway to allow private subnet to connect out the way

resource "aws_nat_gateway" "prod-nat-gateway" {
    
    subnet_id     = "${aws_subnet.prod-subnet-public-1.id}"

    tags = {
    Name = "VPC Demo - NAT"
    }

    # To ensure proper ordering, add Internet Gateway as dependency
    depends_on = [aws_internet_gateway.prod-igw]
}

# Security Group
resource "aws_security_group" "ssh-allowed" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // Do not use this in production, should be limited to your own IP
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ssh-allowed"
    }
}

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"

    tags = {
        Name = "prod-vpc"
    }
}

resource "aws_subnet" "prod-subnet-public-1" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" # This is what makes it a public subnet
    availability_zone = "eu-west-1a"
    tags = {
        Name = "prod-subnet-public-1"
    }
}

resource "aws_subnet" "prod-subnet-private-1" {
    vpc_id = "${aws_vpc.prod-vpc.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-west-1a"
    tags = {
        Name = "prod-subnet-private-1"
    }
}
