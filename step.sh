#!/bin/bash

formatted_output_file_path="$BITRISE_STEP_FORMATTED_OUTPUT_FILE_PATH"

function echo_string_to_formatted_output {
  echo "$1" >> $formatted_output_file_path
}

function write_section_to_formatted_output {
  echo '' >> $formatted_output_file_path
  echo "$1" >> $formatted_output_file_path
  echo '' >> $formatted_output_file_path
}

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
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: MailGun API key is missing."
    exit 1
fi

# Domain
if [[ ! $MAILGUN_DOMAIN ]]; then
	echo
    echo "No MailGun Domain provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: MailGun domain is missing."
    exit 1
fi

# send to address
if [[ ! $MAILGUN_SEND_TO ]]; then
	echo
    echo "No send to address provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: No send to address provided."
    exit 1
fi

# email message
if [[ ! $MAILGUN_EMAIL_MESSAGE ]]; then
	echo
    echo "No email message provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: No email message provided."
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

  # email subject
  if [[ ! $MAILGUN_EMAIL_SUBJECT ]]; then
    echo
      echo "No email subject provided as environment variable. It is not recommended to send an email without subject."
      echo
      write_section_to_formatted_output "Warning: No email subject provided! It is not recommended to send an email without subject."
  fi
  
  write_section_to_formatted_output "#E-mail successfully sent!"
  write_section_to_formatted_output "### Subject:"
  write_section_to_formatted_output "${MAILGUN_EMAIL_SUBJECT}"
  write_section_to_formatted_output "### Message:"
  write_section_to_formatted_output "${MAILGUN_EMAIL_MESSAGE}"
  exit 0
else
  write_section_to_formatted_output "#Error ${http_code}"
  write_section_to_formatted_output "E-mail send failed!"
  exit 1
fi