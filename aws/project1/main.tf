provider "aws" {
    region = "us-east-1" 
}

resource "aws_instance" "ubuntu_server" {
    ami           = "ami-0fc5d935ebf8bc3bc" # Ubuntu Server 22.04 LTS for us-east-1
    instance_type = "t2.micro"

    tags = {
        Name = "ubuntu-server"
    }
}