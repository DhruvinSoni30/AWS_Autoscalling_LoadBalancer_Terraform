# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# fetching AMI ID
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  owners = ["765631733981"]
}

# create launch configuration
resource "aws_launch_configuration" "custom-launch-config" {
  name            = "${var.project_name}-config"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [var.public_ec2_security_group]
  user_data       = file("container.sh")

}

# create auto scalling group
resource "aws_autoscaling_group" "custom-autoscaling-group" {
  name                      = "${var.project_name}-auto-scalling-group"
  vpc_zone_identifier       = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  launch_configuration      = aws_launch_configuration.custom-launch-config.name
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 100
  health_check_type         = "EC2"
  force_delete              = true

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
resource "aws_cloudwatch_metric_alarm" "custom-cloudwatch-alarm" {
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
resource "aws_cloudwatch_metric_alarm" "custom-cloudwatch-alarm" {
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