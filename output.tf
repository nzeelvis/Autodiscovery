output "ansible_IP" {
  value       = aws_instance.PA_ansible.private_ip
  description = "Ansible private IP"
}

output "Bastionhost_IP" {
  value       = aws_instance.Bastion_host.public_ip
  description = "Bastion host IP"
}

output "docker_IP" {
  value       = aws_instance.PA_Docker_Host.private_ip
  description = "Docker private IP"
}

output "jenkins_lb_dns" {
  value       = aws_elb.jenkins_lb.dns_name
  description = "jenkins_lb"
}


output "docker_lb_dns" {
  value       = aws_lb.docker_alb.dns_name
  description = "docker_lb"
}

output "jenkinsprivate_IP" {
  value       = aws_instance.PA_Jenkins.private_ip
  description = "jenkins private IP"
}
