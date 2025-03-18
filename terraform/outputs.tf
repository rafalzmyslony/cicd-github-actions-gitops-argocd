output "instance_id" {
  value = aws_instance.spot_instance.id
}

output "public_ip" {
  value = aws_instance.spot_instance.public_ip
}
