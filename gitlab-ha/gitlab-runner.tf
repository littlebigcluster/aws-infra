module "gitlab-runner" {
  source = "./gitlab-runner"
  # depends_on = ["${aws_autoscaling_group.gitlab_autoscaling.name}"]

  aws_region              = "${var.aws_region}"
  environment             = "${local.environment}"
  key_name                = "${var.key_name}"

  vpc_id                  = "${var.vpc_id}"
  subnet_id_gitlab_runner = "${element(var.subnet_idz, 2)}"
  subnet_id_runners       = "${element(var.subnet_idz, 2)}"

  runners_name            = "${local.runner_name}"
  runners_gitlab_url      = "${local.gitlab_url}"
  runners_token           = "${var.runner_token}"
  runners_token_trinita   = "${var.runner_token_trinita}"
  runners_off_peak_timezone   = "Europe/Paris"
  runners_off_peak_idle_count = 0
  runners_off_peak_idle_time  = 60

# working 8 to 19 :)
  runners_off_peak_periods = "[\"* * 0-8,19-23 * * mon-fri *\", \"* * * * * sat,sun *\"]"

}
