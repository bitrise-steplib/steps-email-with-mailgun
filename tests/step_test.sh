#!/bin/bash

#
# Run it from the directory which contains step.sh
#


# ------------------------
# --- Helper functions ---

function print_and_do_command {
  echo "$ $@"
  $@
}

function inspect_test_result {
  if [ $1 -eq 0 ]; then
    test_results_success_count=$[test_results_success_count + 1]
  else
    test_results_error_count=$[test_results_error_count + 1]
  fi
}

#
# First param is the expect message, other are the command which will be executed.
#
function expect_success {
  expect_msg=$1
  shift

  echo " -> $expect_msg"
  $@
  cmd_res=$?

  if [ $cmd_res -eq 0 ]; then
    echo " [OK] Expected zero return code, got: 0"
  else
    echo " [ERROR] Expected zero return code, got: $cmd_res"
    exit 1
  fi
}

#
# First param is the expect message, other are the command which will be executed.
#
function expect_error {
  expect_msg=$1
  shift

  echo " -> $expect_msg"
  $@
  cmd_res=$?

  if [ ! $cmd_res -eq 0 ]; then
    echo " [OK] Expected non-zero return code, got: $cmd_res"
  else
    echo " [ERROR] Expected non-zero return code, got: 0"
    exit 1
  fi
}

function is_dir_exist {
  if [ -d "$1" ]; then
    return 0
  else
    return 1
  fi
}

function is_file_exist {
  if [ -f "$1" ]; then
    return 0
  else
    return 1
  fi
}

function is_not_unset_or_empty {
  if [[ $1 ]]; then
    return 0
  else
    return 1
  fi
}

function test_env_cleanup {
  unset MAILGUN_API_KEY
	unset MAILGUN_DOMAIN
	unset MAILGUN_SEND_TO
	unset MAILGUN_EMAIL_SUBJECT
	unset MAILGUN_EMAIL_MESSAGE
}

function print_new_test {
  echo
  echo "[TEST]"
}

# -----------------
# --- Run tests ---


echo "Starting tests..."

test_results_success_count=0
test_results_error_count=0


# [TEST] Call the command with MAILGUN_API_KEY not set, 
# it should raise an error message and exit
# 
(
  print_new_test
	test_env_cleanup

  # Set env var
  export MAILGUN_DOMAIN="dsa4321"
  export MAILGUN_SEND_TO="some@email.com"
  export MAILGUN_EMAIL_SUBJECT="Bitrise Email Test"
  export MAILGUN_EMAIL_MESSAGE="It works from tests!"

   # All of the required env vars should exist except MAILGUN_API_KEY
  expect_error "MAILGUN_API_KEY environment variable should NOT be set" is_not_unset_or_empty "$MAILGUN_API_KEY"
  expect_success "MAILGUN_DOMAIN environment variable should be set" is_not_unset_or_empty "$MAILGUN_DOMAIN"
  expect_success "MAILGUN_SEND_TO environment variable should be set" is_not_unset_or_empty "$MAILGUN_SEND_TO"
  expect_success "MAILGUN_EMAIL_SUBJECT environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_SUBJECT"
	expect_success "MAILGUN_EMAIL_MESSAGE environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_MESSAGE"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


# [TEST] Call the command with MAILGUN_DOMAIN not set, 
# it should raise an error message and exit
# 
(
  print_new_test
	test_env_cleanup

  # Set env var
  export MAILGUN_API_KEY="asd1234"
  export MAILGUN_SEND_TO="some@email.com"
  export MAILGUN_EMAIL_SUBJECT="Bitrise Email Test"
  export MAILGUN_EMAIL_MESSAGE="It works from tests!"

   # All of the required env vars should exist except MAILGUN_DOMAIN
  expect_success "MAILGUN_API_KEY environment variable should be set" is_not_unset_or_empty "$MAILGUN_API_KEY"
  expect_error "MAILGUN_DOMAIN environment variable should NOT be set" is_not_unset_or_empty "$MAILGUN_DOMAIN"
  expect_success "MAILGUN_SEND_TO environment variable should be set" is_not_unset_or_empty "$MAILGUN_SEND_TO"
  expect_success "MAILGUN_EMAIL_SUBJECT environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_SUBJECT"
	expect_success "MAILGUN_EMAIL_MESSAGE environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_MESSAGE"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


# [TEST] Call the command with MAILGUN_SEND_TO not set, 
# it should raise an error message and exit
# 
(
  print_new_test
	test_env_cleanup

  # Set env var
  export MAILGUN_API_KEY="asd1234"
  export MAILGUN_DOMAIN="dsa4321"
  export MAILGUN_EMAIL_SUBJECT="Bitrise Email Test"
  export MAILGUN_EMAIL_MESSAGE="It works from tests!"

   # All of the required env vars should exist except MAILGUN_SEND_TO
  expect_success "MAILGUN_API_KEY environment variable should be set" is_not_unset_or_empty "$MAILGUN_API_KEY"
  expect_success "MAILGUN_DOMAIN environment variable should be set" is_not_unset_or_empty "$MAILGUN_DOMAIN"
  expect_error "MAILGUN_SEND_TO environment variable should NOT be set" is_not_unset_or_empty "$MAILGUN_SEND_TO"
  expect_success "MAILGUN_EMAIL_SUBJECT environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_SUBJECT"
	expect_success "MAILGUN_EMAIL_MESSAGE environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_MESSAGE"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


# an email can be sent without subject but it is not recommended


# [TEST] Call the command with MAILGUN_EMAIL_MESSAGE not set, 
# it should raise an error message and exit
# 
(
  print_new_test
  test_env_cleanup

  # Set env var
  export MAILGUN_API_KEY="asd1234"
  export MAILGUN_DOMAIN="dsa4321"
  export MAILGUN_SEND_TO="asd1234"
  export MAILGUN_EMAIL_SUBJECT="Bitrise Email Test"

   # All of the required env vars should exist except MAILGUN_SEND_TO
  expect_success "MAILGUN_API_KEY environment variable should be set" is_not_unset_or_empty "$MAILGUN_API_KEY"
  expect_success "MAILGUN_DOMAIN environment variable should be set" is_not_unset_or_empty "$MAILGUN_DOMAIN"
  expect_success "MAILGUN_SEND_TO environment variable should be set" is_not_unset_or_empty "$MAILGUN_SEND_TO"
  expect_success "MAILGUN_EMAIL_SUBJECT environment variable should be set" is_not_unset_or_empty "$MAILGUN_EMAIL_SUBJECT"
  expect_error "MAILGUN_EMAIL_MESSAGE environment variable should NOT be set" is_not_unset_or_empty "$MAILGUN_EMAIL_MESSAGE"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


#final cleanup
test_env_cleanup

# --------------------
# --- Test Results ---

echo
echo "--- Results ---"
echo " * Errors: $test_results_error_count"
echo " * Success: $test_results_success_count"
echo "---------------"

if [ $test_results_error_count -eq 0 ]; then
  echo "-> SUCCESS"
else
  echo "-> FAILED"
fi
