#!/bin/bash

echo
echo "MAILGUN_API_KEY: $MAILGUN_API_KEY"
echo "MAILGUN_DOMAIN: $MAILGUN_DOMAIN"
echo "MAILGUN_SEND_TO: $MAILGUN_SEND_TO"
echo "MAILGUN_EMAIL_SUBJECT: $MAILGUN_EMAIL_SUBJECT"
echo "MAILGUN_EMAIL_MESSAGE: $MAILGUN_EMAIL_MESSAGE"

# Required input validation
# API key
if [[ ! $MAILGUN_API_KEY ]]; then
	echo
    echo "No API Key provided as environment variable. Terminating..."
    echo
    exit 1
fi

# Domain
if [[ ! $MAILGUN_DOMAIN ]]; then
	echo
    echo "No MailGun Domain provided as environment variable. Terminating..."
    echo
    exit 1
fi

# send to address
if [[ ! $MAILGUN_SEND_TO ]]; then
	echo
    echo "No send to address provided as environment variable. Terminating..."
    echo
    exit 1
fi

# email subject
if [[ ! $MAILGUN_EMAIL_SUBJECT ]]; then
	echo
    echo "No email subject provided as environment variable. It is not recommended to send an email without subject."
    echo
fi

# email message
if [[ ! $MAILGUN_EMAIL_MESSAGE ]]; then
	echo
    echo "No email message provided as environment variable. Terminating..."
    echo
    exit 1
fi


######################

res=$(curl -is --user "api:$MAILGUN_API_KEY" \
  https://api.mailgun.net/v2/$MAILGUN_DOMAIN/messages \
  -F from="Concrete Mailgun Step <postmaster@$MAILGUN_DOMAIN>" \
  -F to="$MAILGUN_SEND_TO" \
  -F subject="$MAILGUN_EMAIL_SUBJECT" \
  --form-string html="$MAILGUN_EMAIL_MESSAGE")

echo
echo " --- Result ---"
echo "$res"
echo " --------------"

http_code=$(echo "$res" | grep HTTP/ | awk {'print $2'} | tail -1)
echo " [i] http_code: $http_code"

if [ "$http_code" == "200" ]; then
  exit 0
else
  exit 1
fi