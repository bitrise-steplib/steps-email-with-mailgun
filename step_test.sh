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
  unset api_key
	unset domain
	unset send_to
	unset subject
	unset message
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


# [TEST] Call the command with api_key not set,
# it should raise an error message and exit
#
(
  print_new_test
	test_env_cleanup

  # Set env var
  export domain="dsa4321"
  export send_to="some@email.com"
  export subject="Bitrise Email Test"
  export message="It works from tests!"

   # All of the required env vars should exist except api_key
  expect_error "api_key environment variable should NOT be set" is_not_unset_or_empty "$api_key"
  expect_success "domain environment variable should be set" is_not_unset_or_empty "$domain"
  expect_success "send_to environment variable should be set" is_not_unset_or_empty "$send_to"
  expect_success "subject environment variable should be set" is_not_unset_or_empty "$subject"
	expect_success "message environment variable should be set" is_not_unset_or_empty "$message"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


# [TEST] Call the command with domain not set,
# it should raise an error message and exit
#
(
  print_new_test
	test_env_cleanup

  # Set env var
  export api_key="asd1234"
  export send_to="some@email.com"
  export subject="Bitrise Email Test"
  export message="It works from tests!"

   # All of the required env vars should exist except domain
  expect_success "api_key environment variable should be set" is_not_unset_or_empty "$api_key"
  expect_error "domain environment variable should NOT be set" is_not_unset_or_empty "$domain"
  expect_success "send_to environment variable should be set" is_not_unset_or_empty "$send_to"
  expect_success "subject environment variable should be set" is_not_unset_or_empty "$subject"
	expect_success "message environment variable should be set" is_not_unset_or_empty "$message"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


# [TEST] Call the command with send_to not set,
# it should raise an error message and exit
#
(
  print_new_test
	test_env_cleanup

  # Set env var
  export api_key="asd1234"
  export domain="dsa4321"
  export subject="Bitrise Email Test"
  export message="It works from tests!"

   # All of the required env vars should exist except send_to
  expect_success "api_key environment variable should be set" is_not_unset_or_empty "$api_key"
  expect_success "domain environment variable should be set" is_not_unset_or_empty "$domain"
  expect_error "send_to environment variable should NOT be set" is_not_unset_or_empty "$send_to"
  expect_success "subject environment variable should be set" is_not_unset_or_empty "$subject"
	expect_success "message environment variable should be set" is_not_unset_or_empty "$message"

  # Send email request
  expect_error "The command should be called, but should not complete sucessfully" print_and_do_command ./step.sh
)
test_result=$?
inspect_test_result $test_result


# an email can be sent without subject but it is not recommended


# [TEST] Call the command with message not set,
# it should raise an error message and exit
#
(
  print_new_test
  test_env_cleanup

  # Set env var
  export api_key="asd1234"
  export domain="dsa4321"
  export send_to="asd1234"
  export subject="Bitrise Email Test"

   # All of the required env vars should exist except send_to
  expect_success "api_key environment variable should be set" is_not_unset_or_empty "$api_key"
  expect_success "domain environment variable should be set" is_not_unset_or_empty "$domain"
  expect_success "send_to environment variable should be set" is_not_unset_or_empty "$send_to"
  expect_success "subject environment variable should be set" is_not_unset_or_empty "$subject"
  expect_error "message environment variable should NOT be set" is_not_unset_or_empty "$message"

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
