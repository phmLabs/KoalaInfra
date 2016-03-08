#
# Initial Recipe to setup Koalamon on AWS and Heroku
#

### AWS Setup
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

### Heroku Setup

provider "heroku" {
  email = "${var.heroku_login_email}"
  api_key = "${var.heroku_login_api_key}"
}

## App Monitor
resource "heroku_app" "monitor" {
  name = "${var.app_name}-${var.app_env}-monitor"
  region = "eu"

  config_vars {
    NODE_ENV = "${var.app_env}"
    LOG_LEVEL = "${lookup(var.log_level,var.app_env)}"
    SYMFONY_ENV = "prod"
    SYMFONY_SECRET = "nDs}VJRe3E3;uvHbtGGDG()Kb2R#HWM44oK"
    AWS_REGION = "${var.aws_region}"
    AWS_ACCESS_KEY = "${var.aws_access_key}"
    AWS_ACCESS_SECRET_KEY = "${var.aws_secret_key}"
    AWS_SQS_QUEUE_URL = "${aws_sqs_queue.koalamon_queue.id}"
    SQS_PUBLISHING_ENABLED = 1
    INTEGRATION_KEY_KOALAPING = "27010d2a-5617-ad4u-9f0d-993edf547abc"
    #S3_BUCKET = "${aws_s3_bucket.monitor.id}"
  }

  depends_on = ["aws_sqs_queue.koalamon_queue"]
}

#resource "heroku_addon" "monitor_postmark" {
#  app = "${heroku_app.monitor.name}"
#  plan = "postmark:${lookup(var.monitor_postmark_size,var.app_env)}"
#}

resource "heroku_addon" "monitor_jawsdb_mysql" {
  count = "${lookup(var.monitor_jawsdb_mysql_install,var.app_env)}"
  app = "${heroku_app.monitor.name}"
  plan = "jawsdb:${lookup(var.monitor_jawsdb_mysql_size,var.app_env)}"
}

resource "heroku_addon" "monitor_scheduler" {
  app = "${heroku_app.monitor.name}"
  plan = "scheduler:standard"
}

# For logentries
#resource "heroku_drain" "monitor" {
#  app = "${heroku_app.monitor.name}"
#  url = "${lookup(var.heroku_log_drain_url,var.app_env)}"
#}

#resource "heroku_domain" "monitor" {
#  app = "${heroku_app.monitor.name}"
#  hostname = "${lookup(var.dns_prefix, var.app_env)}monitor.koalamon.com"
#  depends_on = ["heroku_app.monitor"]
#}


# SSL
resource "heroku_addon" "monitor_ssl" {
  app = "${heroku_app.monitor.name}"
  plan = "ssl"
}
#resource "heroku_cert" "ssl_certificate" {
#  app = "${heroku_app.monitor.name}"
#  certificate_chain = "${file("certificate_chain.crt")}"
#  private_key = "${file("koalamon.key")}"
#  depends_on = ["heroku_addon.ssl"]
#}

# Heroku Test Apps
resource "heroku_app" "testexecutor" {
  count = "${lookup(var.testexecutor_count, var.app_env)}"
  name = "${var.app_name}-${var.app_env}-testexecutor"
  region = "eu"

  config_vars {
    NODE_ENV = "${var.app_env}"
    LOG_LEVEL = "${lookup(var.log_level,var.app_env)}"
    SYMFONY_ENV = "prod"
    SYMFONY_SECRET = "nDs}VJRe3E3;uvHbtGGDG()Kb2R#HWM44oK"
    AWS_SQS_QUEUE_URL = "${aws_sqs_queue.koalamon_queue.id}"
    AWS_REGION = "${var.aws_region}"
    AWS_ACCESS_KEY = "${var.aws_access_key}"
    AWS_ACCESS_SECRET_KEY = "${var.aws_secret_key}"
    #S3_BUCKET = "${aws_s3_bucket.testexecutor.id}"
  }

  depends_on = ["aws_sqs_queue.koalamon_queue"]
}

resource "heroku_addon" "testexecutor_ssl" {
  app = "${heroku_app.testexecutor.name}"
  plan = "ssl"
}

# Queue between testdispatcher and tests
resource "aws_sqs_queue" "koalamon_queue" {
  name = "${var.app_name}-${var.app_env}-koalamon-queue"
}

### Some output
output "HerokuMonitorURL" {
  value = "${heroku_app.monitor.web_url}"
}

output "HerokuMonitorHostname" {
  value = "${heroku_app.monitor.hostname}"
}

output "HerokuTestexecutorURL" {
  value = "${heroku_app.testexecutor.web_url}"
}


# Issue: Heroku Access (for other users)
# Issue: no codeship.io API to create deployment pipeline
