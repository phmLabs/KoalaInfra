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
  monitor_key = "${var.heroku_login_monitor_key}"
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
    #S3_BUCKET = "${aws_s3_bucket.monitor.id}"
  }

  depends_on = ["aws_s3_bucket.monitor"]
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

resource "aws_s3_bucket" "monitor" {
  bucket = "${var.app_name}-${var.app_env}-app-monitor"
  acl = "private"
}

#resource "heroku_domain" "monitor" {
#  app = "${heroku_app.monitor.name}"
#  hostname = "${lookup(var.dns_prefix, var.app_env)}monitor.koalamon.com"
#  depends_on = ["heroku_app.monitor"]
#}


# SSL
resource "heroku_addon" "ssl" {
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
resource "heroku_app" "pagespeed" {
  name = "${var.app_name}-${var.app_env}-pagespeed"
  region = "eu"

  config_vars {
    SQS_QUEUE_URL = "${aws_sqs_queue.pagespeed_queue.id}"
    NODE_ENV = "${var.app_env}"
    LOG_LEVEL = "${lookup(var.log_level,var.app_env)}"
    SYMFONY_ENV = "prod"
    SYMFONY_SECRET = "nDs}VJRe3E3;uvHbtGGDG()Kb2R#HWM44oK"
    AWS_REGION = "${var.aws_region}"
    AWS_ACCESS_KEY = "${var.aws_access_key}"
    AWS_ACCESS_SECRET_KEY = "${var.aws_secret_key}"
    #S3_BUCKET = "${aws_s3_bucket.pagespeed.id}"
  }

  depends_on = ["aws_sqs_queue.pagespeed_queue"]
}

resource "heroku_addon" "ssl" {
  app = "${heroku_app.pagespeed.name}"
  plan = "ssl"
}

# Heroku Dispatcher App
resource "heroku_app" "dispatcher" {
  name = "${var.app_name}-${var.app_env}-dispatcher"
  region = "eu"

  config_vars {
    SQS_PAGESPEED_QUEUE_URL = "${aws_sqs_queue.pagespeed.id}"
    SQS_JS_ERROR_SCANNER_QUEUE_URL = "${aws_sqs_queue.js_error_scanner_queue.id}"
    SQS_KOALA_PING_QUEUE_URL = "${aws_sqs_queue.koala_ping_queue.id}"
    SQS_MISSING_REQUEST_QUEUE_URL = "${aws_sqs_queue.missing_request_queue.id}"
    SQS_SMOKE_QUEUE_URL = "${aws_sqs_queue.smoke_queue.id}"
    NODE_ENV = "${var.app_env}"
    LOG_LEVEL = "${lookup(var.log_level,var.app_env)}"
    AWS_REGION = "${var.aws_region}"
    AWS_ACCESS_KEY = "${var.aws_access_key}"
    AWS_ACCESS_SECRET_KEY = "${var.aws_secret_key}"
    #S3_BUCKET = "${aws_s3_bucket.pagespeed.id}"
  }

  depends_on = ["aws_sqs_queue.pagespeed_queue"]
}

resource "heroku_addon" "ssl" {
  app = "${heroku_app.pagespeed.name}"
  plan = "ssl"
}

# Queue between testdispatcher and tests
resource "aws_sqs_queue" "pagespeed_queue" {
  name = "${var.app_name}-${var.app_env}-pagespeed-queue"
}

resource "aws_sqs_queue" "js_error_scanner_queue" {
  name = "${var.app_name}-${var.app_env}-js-error-scanner-queue"
}

resource "aws_sqs_queue" "koala_ping_queue" {
  name = "${var.app_name}-${var.app_env}-koala-ping-queue"
}

resource "aws_sqs_queue" "missing_request_queue" {
  name = "${var.app_name}-${var.app_env}-missing-request-queue"
}

resource "aws_sqs_queue" "smoke_queue" {
  name = "${var.app_name}-${var.app_env}-smoke-queue"
}

### Some output

output "HerokuWebApi" {
  value = "${heroku_app.monitor.web_url}"
}

output "HerokuApiHostname" {
  value = "${heroku_app.monitor.hostname}"
}

output "WebFrontend" {
  value = "${aws_s3_bucket.koalamon_web_frontend.website_domain}"
}


# Issue: Heroku Access (for other users)
# Issue: no codeship.io API to create deployment pipeline
