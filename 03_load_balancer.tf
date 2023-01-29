######################## load balancer #################################

resource "aws_lb" "js_lb" {
  name               = "js-lb"
  load_balancer_type = "network"
  subnets            = aws_subnet.public_subnet.id

  enable_cross_zone_load_balancing = true
    
  tags = merge(var.project_tags, {
    Name = "js_load_balancer"
  })
}

resource "aws_lb_listener" "js_lb_listener" {
  for_each = var.ports

  load_balancer_arn = aws_lb.js_lb.arn

  protocol          = "TCP"
  port              = each.value

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.js_lb[each.key].arn
  }
    depends_on = [
    aws_lb.js_lb,aws_lb_target_group.js_lb_target_group
  ]
}

resource "aws_lb_target_group" "js_lb_target_group" {
  for_each    = var.ports
  name        = "js_target_group"
  port        = each.value
  protocol    = "TCP"
  vpc_id      = aws_vpc.js_vpc.id
}

resource "aws_autoscaling_group" "js_autoscaling_group" {
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  force_delete       = true
  target_group_arn   = aws_lb_target_group.js_lb[each.key].arn
  health_check_type  = "ELB"
  #vpc_zone_identifier = [aws_subnet.public_subnet.id,aws_subnet.private_subnet.id]

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tags = merge(var.project_tags, {
    Name = "js_js_autoscaling_group"
  })

  depends_on = [
    aws_lb.js_lb
  ]
}

resource "aws_autoscaling_attachment" "js_autoscaling_group_attachment" {
  lb_target_group_arn    = aws_lb_target_group.js_lb_target_group[each.key].arn
  autoscaling_group_name = aws_autoscaling_group.js_autoscaling_group.name
}