# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# fetching AMI ID
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
  owners = ["amazon"]
}

# create launch configuration
resource "aws_launch_configuration" "custom-launch-config" {
  name            = "${var.project_name}-config"
  image_id        = data.aws_ami.amazon_linux_2.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [var.public_ec2_security_group]
  user_data       = data.template_file.user_data.rendered
  lifecycle {
    create_before_destroy = true
  }

}

# create auto scalling group
resource "aws_autoscaling_group" "custom-autoscaling-group" {
  name                      = "${var.project_name}-auto-scalling-group"
  vpc_zone_identifier       = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  launch_configuration      = aws_launch_configuration.custom-launch-config.name
  max_size                  = var.max_size
  min_size                  = var.min_size
  target_group_arns         = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = "custom-ec2-instance"
    propagate_at_launch = true
  }

}

# create auto scalling policy (scale out)
resource "aws_autoscaling_policy" "custom-autoscaling-policy-scale-out" {
  name                   = "${var.project_name}-auto-scalling-policy-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.custom-autoscaling-group.name
  policy_type            = "SimpleScaling"
}

# create cloudwatch alarm (scale out)
resource "aws_cloudwatch_metric_alarm" "custom-cloudwatch-alarm-scale-out" {
  alarm_name          = "${var.project_name}-scale-out- alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.custom-autoscaling-group.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.custom-autoscaling-policy-scale-out.arn]
}

# create auto scalling policy (scale in)
resource "aws_autoscaling_policy" "custom-autoscaling-policy-scale-in" {
  name                   = "${var.project_name}-auto-scalling-policy-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.custom-autoscaling-group.name
  policy_type            = "SimpleScaling"
}

# create cloudwatch alarm (scale in)
resource "aws_cloudwatch_metric_alarm" "custom-cloudwatch-alarm-scale-in" {
  alarm_name          = "${var.project_name}-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.custom-autoscaling-group.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.custom-autoscaling-policy-scale-in.arn]
}