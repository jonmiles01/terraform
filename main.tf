provider "aws" {
  region = "eu-west-2"
}

resource "aws_launch_configuration" "ami_ubuntu" {
  ami           = "ami-07aba4cc9cb368364"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]


 provisioner "local-exec" {
    command = <<EOH
      sudo yum -y update
      sudo yum install -y python3.6
    EOH
  }

  user_data = "${file("${path.module}/app.py")}"

  tags {
    Name = "flask_app"
  }
}

resource "aws_security_group" "allow_https_traffic" {
  name = "allow_https_traffic"
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

  tags = {
  Name = "flask_application"
}


resource "aws_autoscaling_group" "app_asg" {
  launch_configuration = aws_launch_configuration.flask_app.id
  min_size = 2
  max_size = 10
  tag {
    key                 = "terraform-asg-nodes"
    value               = "terraform-asg-nodes"
    propagate_at_launch = true
  }
}

resource "aws_elb" "aws_elb" {
  name               = "aws_elb"
  availability_zones = data.aws_availability_zones.all.names
  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}
