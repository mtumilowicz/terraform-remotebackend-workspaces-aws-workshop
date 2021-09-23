output "container-name" {
  value       = docker_container.http_server_container[*].name
  description = "The name of the container"
}

output "ip-address" {
  value       = [for container in docker_container.http_server_container[*] : join(":", [container.ip_address], container.ports[*]["external"])]
  description = "The IP address and external port of the container"
}