output "webserver_lb_dns" {
  description = "Webserver ALB DSN name"
  value       = aws_lb.webserver_lb.dns_name
}

output "webserver_ns_name" {
  description = "Webserver private DNS namespace name"
  value       = aws_service_discovery_private_dns_namespace.webserver_service_discovery_ns.name
}

output "webserver_service_1_name" {
  description = "Webserver service 1 name"
  value       = aws_service_discovery_service.web_service_1.name
}

output "webserver_service_2_name" {
  description = "Webserver service 2 name"
  value       = aws_service_discovery_service.web_service_2.name
}
