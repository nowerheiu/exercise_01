######################## Ubuntu image #################################

data "aws_ami" "ubuntu_2004" {
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

######################## NIC #################################

resource "aws_network_interface" "js_network_interface" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.2.4"]

  tags = merge(var.project_tags, {
    Name = "js_private_network_interface"
  })
}

######################## instance #################################

resource "aws_key_pair" "ssh-key" {
  key_name   = "js_ssh-key"
  public_key = "./js_test01.pem.pub"
}

resource "aws_instance" "js_instance" {
  ami           = data.aws_ami.ubuntu_2004.id #ami-0778521d914d23bc1 ubuntu 2004
  instance_type = "t2.micro"
  key_name      = "js_ssh-key"


  network_interface {
    network_interface_id = aws_network_interface.js_network_interface.id
    device_index         = 0
  }
  
  vpc_security_group_ids      = [aws_security_group.js_security_group.id]
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin    
    sudo systemctl start docker
    sudo systemctl enable docker
  EOF

  tags = merge(var.project_tags, {
    Name = "js_instance"
  })
}