{
  "checks": {
    "check-disk": {
    "handlers": ["mailer"],
    "command": "/opt/sensu/embedded/bin/check-disk-usage.rb -x debugfs,tracefs",
    "interval": 60,
    "occurrences": 5,
    "subscribers": [ "stage", "core" , "ALL" , "prod" ]
    }
  }
}
