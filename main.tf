## Settings
provider "aws" {
    region = "${var.region}" 
}

resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"
  assume_role_policy = "${file("roles/assume-role-ec2-policy.json")}"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = "${aws_iam_role.ec2_iam_role.name}"
}

resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  	  name = "ec2_iam_role_policy"
  	  role = "${aws_iam_role.ec2_iam_role.id}"
  	  policy = "${file("roles/role-ec2-instance.json")}"
}

data "template_file" "bootstrap_ec2" {
 template = "${file("user-data/bootstrap.sh.tpl")}"

 vars {
   s3_bucket = "${var.s3_bucket}"
 }
}
resource "aws_key_pair" "default" {
  key_name = "ec2-elb-key"
  public_key = "${file("${var.key_path}")}"
}

#### Launch Configuration EC2
resource "aws_launch_configuration" "webcluster" {
    image_id=  "${var.ami}"
    instance_type = "${var.instance_type}"
    security_groups = ["${aws_security_group.websg.id}"]
    iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_profile.id}"
    key_name = "${aws_key_pair.default.key_name}"
    user_data = "${data.template_file.bootstrap_ec2.rendered}"

    lifecycle {
        create_before_destroy = true
    }
}

###  AutoScalingGroup
resource "aws_autoscaling_group" "scalegroup" {
	launch_configuration = "${aws_launch_configuration.webcluster.name}"
    availability_zones = ["us-east-1a","us-east-1b","us-east-1c"]
    min_size = 3
    max_size = 6
    desired_capacity = 3
    enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
    metrics_granularity="1Minute"
    load_balancers= ["${aws_elb.elb1.id}"]
    health_check_type="ELB"
    tag {
        key = "Name"
        value = "webserver_rl42"
        propagate_at_launch = true
    }
}

###  AutoScaling Policy
resource "aws_autoscaling_policy" "autopolicy" {
    name = "AutoScaling-autoplicy CPU normalized"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.scalegroup.name}"
}

#### AutoScaling Policy Down
resource "aws_autoscaling_policy" "autopolicy-down" {
    name = "AutoScaling-autoplicy-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.scalegroup.name}"
}

### CloudWatch cpu ultilization Alarm 
	resource "aws_cloudwatch_metric_alarm" "cpualarm" {
    alarm_name = "CPU-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "60"

    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.scalegroup.name}"
    }

    alarm_description = "This metric monitor EC2 instance cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.autopolicy.arn}"]
}

#### CloudWatch delete the new instance
	resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
    alarm_name = "CPU-alarm-down"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "10"

    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.scalegroup.name}"
    }

    alarm_description = "This metric monitor EC2 instance cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.autopolicy-down.arn}"]
}

### Security Group ELB port 80
	resource "aws_security_group" "elbsg" {
    name = "security_group_for_elb"
    vpc_id = "${var.vpc_id}"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

### Security Group External ports 80,8080 ,22
resource "aws_security_group" "websg" {
    name = "security_group_for_web_server"
    vpc_id = "${var.vpc_id}"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group_rule" "elb_add" {
  description              = "Allow elb to communicate with nodes"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.websg.id}"
  source_security_group_id = "${aws_security_group.elbsg.id}"
  depends_on = [ "aws_security_group.elbsg","aws_security_group.websg" ]
}

resource "aws_elb" "elb1" {
    name = "terraform-elb"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    security_groups = ["${aws_security_group.elbsg.id}"]

    listener {
        instance_port = 8080
        instance_protocol = "http"
        lb_port = 80
        lb_protocol = "http"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:8080/hello"
        interval = 30
    }

    cross_zone_load_balancing = true
    idle_timeout = 400
    connection_draining = true
    connection_draining_timeout = 200

    tags {
        Name = "terraform-elb"
    }
}

### Cookie expiration
resource "aws_lb_cookie_stickiness_policy" "cookie_stickness" {
    name = "cookiestickness"
    load_balancer = "${aws_elb.elb1.id}"
    lb_port = 80
    cookie_expiration_period = 10
}

### Output A-Zs
output "availabilityzones" {
    value = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

### Output dns ELB
output "elb-dns" {
    value = "${aws_elb.elb1.dns_name}"
}
