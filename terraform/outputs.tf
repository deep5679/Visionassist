output "website_url" {
  description = "Open this URL in a browser after 2-3 minutes"
  value       = "http://${aws_instance.web.public_ip}"
}

output "instance_id" {
  value = aws_instance.web.id
}
