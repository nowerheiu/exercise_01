data "aws_ami" "ubuntu_20.04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_network_interface" "js_network_interface" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.2.4"]

  tags = merge(var.project_tags, {
    Name = "js_private_network_interface"
  })
}

resource "aws_key_pair" "js_ssh-key" {
  key_name   = "js_ssh-key"
  public_key = "./js_test01.pem.pub"
}

resource "aws_instance" "js_instance" {
  ami           = data.aws_ami.ubuntu_20.04.id #ami-0778521d914d23bc1 ubuntu 2004
  instance_type = "t2.micro"
  key_name      = "js_ssh-key"


  network_interface {
    network_interface_id = aws_network_interface.js_network_interface.id
    device_index         = 0
  }
  
  vpc_security_group_ids      = [aws_security_group.js_security_group.id]
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
  EOF

  tags = merge(var.project_tags, {
    Name = "js_instance"
  })
}