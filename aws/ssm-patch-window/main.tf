provider "aws" {
  profile = "${var.profile}"
  region  = "${var.region}"
}
resource "aws_ssm_maintenance_window" "window" {
  name     = "Patch-maintenance-window"
  schedule = "${var.cron}"
  duration = "${var.duration}"
  cutoff   = "${var.cutoff_time}"
}

resource "aws_ssm_maintenance_window_target" "target1" {
  window_id     = "${aws_ssm_maintenance_window.window.id}"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:os_type"
    values = ["RedHat6","CentOS6","AmazonLinux2","Ubuntu16"]
  }
}

resource "aws_iam_service_linked_role" "ssm" {
  aws_service_name = "ssm.amazonaws.com"
  description = "Service Linked Role for Maintenance Windows to execute tasks"
}

resource "aws_ssm_maintenance_window_task" "task" {
  window_id        = "${aws_ssm_maintenance_window.window.id}"
  name             = "Run-Patch-Baseline-Document"
  description      = "Task to Install Patches to Linux Instances"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = "${aws_iam_service_linked_role.ssm.arn}"
  max_concurrency  = "3"
  max_errors       = "10"

  targets {
    key    = "WindowTargetIds"
    values = ["${aws_ssm_maintenance_window_target.target1.id}"]
  }

  task_parameters {
    name   = "Operation"
    values = ["${var.patch_operation}"]
  }

  logging_info {
    s3_bucket_name = "${var.log_bucket_name}"
    s3_region = "${var.region}"
    s3_bucket_prefix = "${var.profile}/PatchingLogs"
  }
}