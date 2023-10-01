# Create VPC
resource "aws_vpc" "PA_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "PA_vpc"
  }
}

# Create Public Subnet 1
resource "aws_subnet" "PA_pub_sn1" {
  vpc_id            = aws_vpc.PA_vpc.id
  cidr_block        = var.pubsub1_cidr
  availability_zone = "eu-west-2a"
  tags = {
    Name = "PA_pub_sn1"
  }
}

# Create Public Subunet 2
resource "aws_subnet" "PA_pub_sn2" {
  vpc_id            = aws_vpc.PA_vpc.id
  cidr_block        = var.pubsub2_cidr
  availability_zone = "eu-west-2b"
  tags = {
    Name = "PA_pub_sn2"
  }
}

# Create Private Subnet 1
resource "aws_subnet" "PA_prv_sn1" {
  vpc_id            = aws_vpc.PA_vpc.id
  cidr_block        = var.prv_sub1_cidr
  availability_zone = "eu-west-2a"
  tags = {
    Name = "PA_prv_sn1"
  }
}

# Create Private Subnet 2
resource "aws_subnet" "PA_prv_sn2" {
  vpc_id            = aws_vpc.PA_vpc.id
  cidr_block        = var.prv_sub2_cidr
  availability_zone = "eu-west-2b"
  tags = {
    Name = "PA_prv_sn2"
  }
}

# Craete Internet Gateway
resource "aws_internet_gateway" "PA_igw" {
  vpc_id = aws_vpc.PA_vpc.id
  tags = {
    Name = "PA_igw"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "PA_nat_eip" {
  depends_on = [aws_internet_gateway.PA_igw]
  tags = {
    Name = "PA_nat_eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "PA_ngw" {
  allocation_id = aws_eip.PA_nat_eip.id
  subnet_id     = aws_subnet.PA_pub_sn1.id
  tags = {
    Name = "PA_ngw"
  }
  # Explicit Dependency
  depends_on = [aws_internet_gateway.PA_igw]
}

# Create Route-Table for Public Subnet
resource "aws_route_table" "PA_pub_rt" {
  vpc_id = aws_vpc.PA_vpc.id

  route {
    cidr_block = var.all_ip
    gateway_id = aws_internet_gateway.PA_igw.id
  }
}

# Create Route-Table for Private Subnet
resource "aws_route_table" "PA_prv_rt" {
  vpc_id = aws_vpc.PA_vpc.id

  route {
    cidr_block     = var.all_ip
    nat_gateway_id = aws_nat_gateway.PA_ngw.id
  }
}

# Create Route-Table Association for Public Subnet 1
resource "aws_route_table_association" "PA_pub_sub_rt_as1" {
  subnet_id      = aws_subnet.PA_pub_sn1.id
  route_table_id = aws_route_table.PA_pub_rt.id
}
# Create Route-Table Association for Public Subnet 2
resource "aws_route_table_association" "PA_pub_sub_rt_as2" {
  subnet_id      = aws_subnet.PA_pub_sn2.id
  route_table_id = aws_route_table.PA_pub_rt.id
}

# Create Route-Table Association for Private Subnet 1
resource "aws_route_table_association" "PA_prv_sub_rt_as1" {
  subnet_id      = aws_subnet.PA_prv_sn1.id
  route_table_id = aws_route_table.PA_prv_rt.id
}

# Create Route-Table Association for Private Subnet 2
resource "aws_route_table_association" "PA_prv_sub_rt_as2" {
  subnet_id      = aws_subnet.PA_prv_sn2.id
  route_table_id = aws_route_table.PA_prv_rt.id
}

# Create Ansible Security Group
resource "aws_security_group" "PA_ansible_sg" {
  name        = "PA-ansible-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.PA_vpc.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PA_ansible_sg"
  }
}

# Create docker security group
resource "aws_security_group" "PA_docker_sg" {
  name        = "PA_docker_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.PA_vpc.id


  ingress {
    description = "docker"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.prv_sub1_cidr]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.prv_sub1_cidr]
  }


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.prv_sub1_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ip]
  }

  tags = {
    Name = "PA_docker_sg"
  }
}

# Security group for Bastion Host
resource "aws_security_group" "PA_bastion_sg" {
  name        = "PA_bastion_sg"
  description = "Allow traffic for ssh"
  vpc_id      = aws_vpc.PA_vpc.id

  ingress {
    description = "Allow ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ip]
  }

  tags = {
    Name = "PA_bastion_sg"
  }
}

# Create Jenkins Security Group
resource "aws_security_group" "PA_jenkins_sg" {
  name        = "PA_jenkins_sg"
  description = "Allow 8080,ssh traffic"
  vpc_id      = aws_vpc.PA_vpc.id

  ingress {
    description = "Allow 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.all_ip]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.all_ip]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ip]
  }
  tags = {
    Name = "PA_jenkins_sg"
  }
}

# RDS Security Group
resource "aws_security_group" "PA_RDS_sg" {
  name        = "PA_RDS_sg"
  description = "allow mysql traffic"
  vpc_id      = aws_vpc.PA_vpc.id
  tags = {
    Name = "PA_RDS_sg"
  }

  ingress {
    description = "RDS"
    from_port   = var.mysql_cidr
    to_port     = var.mysql_cidr
    protocol    = "tcp"
    cidr_blocks = [var.all_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ip]
  }
}
# Create db Subnet group
resource "aws_db_subnet_group" "db_subnet-group" {
  name       = "db_subnet-group"
  subnet_ids = [aws_subnet.PA_prv_sn1.id, aws_subnet.PA_prv_sn2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Create RDS instance
resource "aws_db_instance" "nze_database" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.db_subnet-group.id
  db_name                = "admin"
  vpc_security_group_ids = [aws_security_group.PA_RDS_sg.id]
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "admin123"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
}

#create ansible server 
resource "aws_instance" "PA_ansible" {
  ami                    = "ami-035c5dc086849b5de"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.PA_prv_sn1.id
  vpc_security_group_ids = [aws_security_group.PA_ansible_sg.id]
  key_name               = aws_key_pair.cam.key_name
  iam_instance_profile   = aws_iam_instance_profile.ansible_node_instance_profile.id

  tags = {
    Name = "PA_ansible"
  }
  user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install python3-pip -y
sudo alternatives --set python /usr/bin/python3
sudo pip3 install docker-py
sudo yum install ansible -y
sudo yum install -y yum-utils -y
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo systemctl start docker
sudo systemctl enable docker
cd /etc/ansible
sudo yum install unzip -y
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
sudo ln -svf /usr/local/bin/aws /usr/bin/aws
sudo yum install vim -y
touch MyPlaybook.yaml
touch key.pem
sudo chmod 400 key.pem
touch discovery.sh
sudo chmod 755 discovery.sh
sudo chown -R ec2-user:ec2-user /etc/ansible && chmod +x /etc/ansible
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo  NEW_RELIC_API_KEY=NRAK-QKLYCGNC982V2O89HWGBOLNOV0G NEW_RELIC_ACCOUNT_ID=4020397 NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y
sudo hostnamectl set-hostname ansible
EOF
}

# Provisioning Bastion Host
resource "aws_instance" "Bastion_host" {
  ami                         = "ami-035c5dc086849b5de"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.cam.key_name
  subnet_id                   = aws_subnet.PA_pub_sn1.id
  vpc_security_group_ids      = [aws_security_group.PA_bastion_sg.id]
  associate_public_ip_address = true

  provisioner "file" {
    source      = "~/Downloads/keypair/cam"
    destination = "/home/ec2-user/cam"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/keypair/cam")
    host        = self.public_ip
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo su
    sudo chmod 400 cam
    sudo hostnamectl set-hostname Bastion
    EOF
  tags = {
    Name = "Bastion_Host"
  }

}

# JENKINS SERVER
resource "aws_instance" "PA_Jenkins" {
  ami                    = "ami-035c5dc086849b5de"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.PA_prv_sn1.id
  vpc_security_group_ids = [aws_security_group.PA_jenkins_sg.id]
  key_name               = aws_key_pair.cam.key_name
  user_data              = local.user_data
  tags = {
    Name = "PA_Jenkins"
  }
}
# Create docker instance
resource "aws_instance" "PA_Docker_Host" {
  ami                    = "ami-035c5dc086849b5de"
  instance_type          = "t2.medium"
  key_name               = "cam"
  subnet_id              = aws_subnet.PA_prv_sn1.id
  vpc_security_group_ids = [aws_security_group.PA_docker_sg.id]
  user_data              = <<-EOF
#!/bin/bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update -y
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo yum install python3 python3-pip -y
sudo alternatives --set python /usr/bin/python3
sudo pip3 install docker-py
docker pull hello-world
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo  NEW_RELIC_API_KEY=NRAK-QKLYCGNC982V2O89HWGBOLNOV0G NEW_RELIC_ACCOUNT_ID=4020397 NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y
EOF
  tags = {
    NAME = "PA_Docker_Host"
  }

}


#IAM instance profile
data "aws_iam_policy_document" "ansible-server" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "autoscaling:Describe*",
      "ec2:DescribeTags*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ansible_server_policy" {
  name        = "ansible-node-aws-cli-policy"
  path        = "/"
  description = "Access policy for Ansible_node to connect to aws account"
  policy      = data.aws_iam_policy_document.ansible-server.json
}

data "aws_iam_policy_document" "ansible_node_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ansible_node_role" {
  name               = "ansible-node-aws-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ansible_node_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ansible_node_policy_attachment" {
  role       = aws_iam_role.ansible_node_role.name
  policy_arn = aws_iam_policy.ansible_server_policy.arn
}

resource "aws_iam_instance_profile" "ansible_node_instance_profile" {
  name = "ansible_node_instance_profile"
  role = aws_iam_role.ansible_node_role.name
}

#Create keypair
resource "aws_key_pair" "cam" {
  key_name   = "cam"
  public_key = file("~/Downloads/keypair/cam.pub")
}

#Create Auto-Scaling group
resource "aws_autoscaling_group" "Dockerhost_ASG" {
  name                      = "Dockerhost_ASG"
  max_size                  = 3
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.Docker_host_ASG_LC.id
  vpc_zone_identifier       = [aws_subnet.PA_prv_sn2.id, aws_subnet.PA_prv_sn1.id]
  target_group_arns         = ["${aws_lb_target_group.ari-tg.arn}"]
  tag {
    key                 = "name"
    value               = "ASG"
    propagate_at_launch = true
  }
}

#Create Auto-Scaling Group Policy
resource "aws_autoscaling_policy" "Dockerhost_ASG_POLICY" {
  autoscaling_group_name = aws_autoscaling_group.Dockerhost_ASG.name
  name                   = "Dockerhost_ASG_POLICY"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
}

#Create Jenkins LB
resource "aws_elb" "jenkins_lb" {
  name            = "jenkins-lb"
  subnets         = [aws_subnet.PA_pub_sn1.id]
  security_groups = [aws_security_group.PA_jenkins_sg.id]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 30
  }

  instances                   = [aws_instance.PA_Jenkins.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "jenkins-lb"
  }
}

#Creating Application Load Balancer For Docker
resource "aws_lb" "docker_alb" {
  name                       = "docker-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.PA_docker_sg.id]
  subnets                    = [aws_subnet.PA_pub_sn2.id, aws_subnet.PA_pub_sn1.id]
  enable_deletion_protection = false
  tags = {
    enviroment = "docker-alb"
  }
}

# Docker target group
resource "aws_lb_target_group" "ari-tg" {
  name     = "ari-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.PA_vpc.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

# Create docker Lb target group attachment
resource "aws_lb_target_group_attachment" "ari_attachment_tg" {
  target_group_arn = aws_lb_target_group.ari-tg.arn
  target_id        = aws_instance.PA_Docker_Host.id
  port             = 80
}
# Create Docker LB Listener
resource "aws_lb_listener" "docker_lb_listener" {
  load_balancer_arn = aws_lb.docker_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ari-tg.arn
  }
}

# Creating ami from instance
resource "aws_ami_from_instance" "Docker_host_AMI" {
  name               = "Docker_host_AMI"
  source_instance_id = aws_instance.PA_Docker_Host.id
  depends_on         = [aws_instance.PA_Docker_Host]
}

# Create auto-scaling
resource "aws_launch_configuration" "Docker_host_ASG_LC" {
  name            = "Docker_host_ASG_LC"
  image_id        = aws_ami_from_instance.Docker_host_AMI.id
  security_groups = [aws_security_group.PA_docker_sg.id]
  instance_type   = "t2.medium"
  key_name        = aws_key_pair.cam.key_name
  user_data       = <<-EOF
#!/bin/bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update -y
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo yum install python3 python3-pip -y
sudo alternatives --set python /usr/bin/python3
sudo pip3 install docker-py
docker pull hello-world
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo  NEW_RELIC_API_KEY=NRAK-QKLYCGNC982V2O89HWGBOLNOV0G NEW_RELIC_ACCOUNT_ID=4020397 NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y
sudo hostnamectl set-hostname dockerHostASG
EOF
}


