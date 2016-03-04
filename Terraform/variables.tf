variable "aws_access_key" {
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
}

variable "aws_region" {
  description = "AWS Region"
  default = "eu-central-1"
}

variable "app_name" {
  description = "Prefix for all resources, e.g. 'koalamon'"
}

variable "app_env" {
  description = "Prefix for all resources, e.g. 'stage'"
}

variable "heroku_login_email" {
  description = "Heroku Login"
}

variable "heroku_login_api_key" {
  description = "Heroku API Key"
}

#variable "heroku_log_drain_url" {
#  description = "URL for Heroku logging drain"
#  default = {
#    stage = "syslog://data.logentries.com:14461"
#    prod = "syslog://data.logentries.com:12719"
#  }
#}

variable "dns_prefix" {
  default = {
    stage = "stage-"
    prod = ""
  }
}

variable "log_level" {
  default = {
    stage = "debug"
    prod = "error"
  }
}

variable "testexecutor_count" {
  default = {
    stage = "1"
    prod = "2"
  }
}

variable "api_postmark_size" {
  default = {
    stage = "10k"
    prod = "10k"
  }
}

variable "api_jawsdb_mysql_size" {
  default = {
    stage = "kitefin"
    prod = "kitefin" #leopard
  }
}

variable "api_jawsdb_mysql_install" {
  default = {
    stage = "1"
    prod = "1"
  }
}