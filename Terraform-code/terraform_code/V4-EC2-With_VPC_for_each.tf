terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  access_key = "AKIAUEPROONACMG4A3UG"
  secret_key = "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"
  region = "us-east-1"
}

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_availability_zones" "available" {
    state = "available"  
}

resource "aws_instance" "demo-server" {
    ami = data.aws_ssm_parameter.ubuntu.value
    instance_type = "t2.micro"
    key_name = "LTIM_Key_Pair"
    //security_groups = [ "demo-sg" ]
    vpc_security_group_ids = [aws_security_group.demo-sg.id]
    subnet_id = aws_subnet.dpp-public-subnet-01.id 
for_each = toset(["jenkins-master", "build-slave", "ansible"])
   tags = {
     Name = "${each.key}"
   }
    
    }

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id = aws_vpc.dpp-vpc.id 
  
  ingress {
    description      = "SHH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
    description      = "Jenkins port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"

  }
}

resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "dpp-vpc"
  }
  
}

resource "aws_subnet" "dpp-public-subnet-01" {
  vpc_id = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "dpp-public-subent-01"
  }
}

resource "aws_subnet" "dpp-public-subnet-02" {
  vpc_id = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "dpp-public-subent-02"
  }
}

resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id 
  tags = {
    Name = "dpp-igw"
  } 
}

resource "aws_route_table" "dpp-public-rt" {
  vpc_id = aws_vpc.dpp-vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id 
  }
}

resource "aws_route_table_association" "dpp-rta-public-subnet-01" {
  subnet_id = aws_subnet.dpp-public-subnet-01.id
  route_table_id = aws_route_table.dpp-public-rt.id   
}

resource "aws_route_table_association" "dpp-rta-public-subnet-02" {
  subnet_id = aws_subnet.dpp-public-subnet-02.id 
  route_table_id = aws_route_table.dpp-public-rt.id   
}

output "availability_zone" {
  value = data.aws_availability_zones.available.names
}