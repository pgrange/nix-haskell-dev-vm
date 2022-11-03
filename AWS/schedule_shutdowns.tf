# Let's shutdown the machine when we're not supposed to work

module "stop-dev-vm" {
  # shutdown every day at 5pm UTC (7pm CEST)
  source                         = "diodonfrost/lambda-scheduler-stop-start/aws"
  name                           = "shutdown"
  cloudwatch_schedule_expression = "cron(0 17 ? * * *)"
  schedule_action                = "stop"
  autoscaling_schedule           = "false"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  cloudwatch_alarm_schedule      = "false"
  scheduler_tag                  = {
    key   = "OfficeHour"
    value = "true"
  }
}
