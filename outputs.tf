output "controller_ips" {
  value = aws_instance.controller[*].public_ip
}

output "compute_ips" {
  value = aws_instance.compute[*].public_ip
}

output "storage_ips" {
  value = aws_instance.storage[*].public_ip
}
