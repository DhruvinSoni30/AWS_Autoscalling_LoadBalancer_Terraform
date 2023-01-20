output "application_load_balancer_dns_name" {
  value = aws_lb.application_load_balancer.dns_name
}

output "alb_id" {
  value = aws_lb.application_load_balancer.id
}

output "alb_arn" {
  value = aws_lb.application_load_balancer.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}