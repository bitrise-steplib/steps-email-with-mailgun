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
echo "api_key: $api_key"
echo "domain: $domain"
echo "send_to: $send_to"
echo "subject: $subject"
echo "message: $message"
echo "attachements: $attachements"
eval attachements_array=(${attachements//,/ })

# Required input validation
# API key
if [[ ! $api_key ]]; then
	echo
    echo "No API Key provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: MailGun API key is missing."
    exit 1
fi

# Domain
if [[ ! $domain ]]; then
	echo
    echo "No MailGun Domain provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: MailGun domain is missing."
    exit 1
fi

# send to address
if [[ ! $send_to ]]; then
	echo
    echo "No send to address provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: No send to address provided."
    exit 1
fi

# email message
if [[ ! $message ]]; then
	echo
    echo "No email message provided as environment variable. Terminating..."
    echo
    write_section_to_formatted_output "# Error!"
    write_section_to_formatted_output "Reason: No email message provided."
    exit 1
fi


######################

attachementRequest=""
if [[ -n $attachements_array ]]; then
  for anAttachement in "${attachements_array[@]}"
  do
    attachementRequest="$attachementRequest -F attachment=@$anAttachement"
  done
fi


res=$(curl -is --user "api:$api_key" \
  https://api.mailgun.net/v2/$domain/messages \
  -F from="Bitrise Mailgun Step <postmaster@$domain>" \
  -F to="$send_to" \
  -F subject="$subject" \
  $attachementRequest \
  --form-string html="$message")

echo
echo " --- Result ---"
echo "$res"
echo " --------------"

http_code=$(echo "$res" | grep HTTP/ | awk {'print $2'} | tail -1)
echo " [i] http_code: $http_code"

if [ "$http_code" == "200" ]; then

  # email subject
  if [[ ! $subject ]]; then
    echo
      echo "No email subject provided as environment variable. It is not recommended to send an email without subject."
      echo
      write_section_to_formatted_output "Warning: No email subject provided! It is not recommended to send an email without subject."
  fi

  write_section_to_formatted_output "#E-mail successfully sent!"
  write_section_to_formatted_output "### Subject:"
  write_section_to_formatted_output "${subject}"
  write_section_to_formatted_output "### Message:"
  write_section_to_formatted_output "${message}"
  exit 0
else
  write_section_to_formatted_output "#Error ${http_code}"
  write_section_to_formatted_output "E-mail send failed!"
  exit 1
fi
