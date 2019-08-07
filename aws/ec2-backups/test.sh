#!/bin/bash

echo "Hello World"
curl -X POST -H 'Content-type: application/json' --data '{"text":"ZZ Test from Jenkins"}' https://hooks.slack.com/services/REDACTED
