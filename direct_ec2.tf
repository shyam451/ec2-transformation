resource "aws_instance" "direct_instances" {
  count         = 2
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2[0].id
  instance_type = "t2.micro"
  subnet_id     = var.subnet_ids != null ? var.subnet_ids[0] : data.aws_subnets.default[0].ids[0]
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
    echo "Hello from direct EC2 instance" > /tmp/hello.txt
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.project_name}-direct-instance-${count.index}"
    Environment = var.environment
  }
}

output "direct_instance_ids" {
  value = aws_instance.direct_instances[*].id
}

output "direct_instance_public_ips" {
  value = aws_instance.direct_instances[*].public_ip
}
