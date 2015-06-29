package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"strings"

	"./markdownlog"
)

const (
	FROM_NAME string = "Bitrise Mailgun Step <postmaster@$MAILGUN_DOMAIN>"
	TYPE_HTML string = "html"
	TYPE_TEXT string = "text"
)

func errorMessageToOutput(msg string) error {
	message := "Message send failed!\n"
	message = message + "Error message:\n"
	message = message + msg

	return markdownlog.ErrorSectionToOutput(message)
}

func successMessageToOutput(from, to, subject, msg string) error {
	message := "Message successfully sent!\n"
	message = message + "From:\n"
	message = message + from + "\n"
	message = message + "To:\n"
	message = message + to + "\n"
	message = message + "Subject:\n"
	message = message + subject + "\n"
	message = message + "Message:\n"
	message = message + msg

	return markdownlog.SectionToOutput(message)
}

func main() {
	// init / cleanup the formatted output
	pth := os.Getenv("BITRISE_STEP_FORMATTED_OUTPUT_FILE_PATH")
	markdownlog.Setup(pth)
	err := markdownlog.ClearLogFile()
	if err != nil {
		fmt.Errorf("Failed to clear log file", err)
	}

	// required inputs
	apiKey := os.Getenv("MAILGUN_API_KEY")
	if apiKey == "" {
		errorMessageToOutput("$MAILGUN_API_KEY is not provided!")
		os.Exit(1)
	}
	domain := os.Getenv("MAILGUN_DOMAIN")
	if domain == "" {
		errorMessageToOutput("$MAILGUN_DOMAIN is not provided!")
		os.Exit(1)
	}
	toName := os.Getenv("MAILGUN_SEND_TO")
	if toName == "" {
		errorMessageToOutput("$MAILGUN_SEND_TO is not provided!")
		os.Exit(1)
	}
	message := os.Getenv("MAILGUN_EMAIL_MESSAGE")
	if message == "" {
		errorMessageToOutput("$MAILGUN_EMAIL_MESSAGE is not provided!")
		os.Exit(1)
	}
	//optional inputs
	subject := os.Getenv("MAILGUN_EMAIL_SUBJECT")
	if subject == "" {
		markdownlog.SectionToOutput("$MAILGUN_EMAIL_SUBJECT is not provided!")
	}
	messageType := os.Getenv("MAILGUN_MESSAGE_TYPE")
	if messageType == "" || (messageType != TYPE_HTML && messageType != TYPE_TEXT) {
		messageType = TYPE_TEXT
	}
	errorToName := os.Getenv("MAILGUN_ERROR_SEND_TO")
	if errorToName == "" {
		markdownlog.SectionToOutput("$MAILGUN_ERROR_SEND_TO is not provided!")
	}
	errorSubject := os.Getenv("MAILGUN_ERROR_EMAIL_SUBJECT")
	if errorSubject == "" {
		markdownlog.SectionToOutput("$MAILGUN_ERROR_EMAIL_SUBJECT is not provided!")
	}
	errorMessage := os.Getenv("MAILGUN_ERROR_EMAIL_MESSAGE")
	if errorMessage == "" {
		markdownlog.SectionToOutput("$MAILGUN_ERROR_EMAIL_MESSAGE is not provided!")
	}

	isBuildFailedMode := (os.Getenv("STEPLIB_BUILD_STATUS") != "0")
	if isBuildFailedMode {
		if errorToName == "" {
			fmt.Println("Build failed, but no MAILGUN_ERROR_SEND_TO defined, use default")
		} else {
			toName = errorToName
		}
		if errorSubject == "" {
			fmt.Println("Build failed, but no MAILGUN_ERROR_EMAIL_SUBJECT defined, use default")
		} else {
			subject = errorSubject
		}
		if errorMessage == "" {
			fmt.Println("Build failed, but no MAILGUN_ERROR_EMAIL_MESSAGE defined, use default")
		} else {
			message = errorMessage
		}
	}

	// request payload
	values := url.Values{
		"from": {FROM_NAME},
		"to":   {toName},
	}
	if messageType == TYPE_HTML {
		values.Set("html", message)
	} else {
		values.Set("text", message)
	}
	if subject != "" {
		values.Set("subject", subject)
	}
	valuesReader := *strings.NewReader(values.Encode())

	// request
	url := "https://api:" + apiKey + "@api.mailgun.net/v3/" + domain + "/messages"

	request, err := http.NewRequest("POST", url, &valuesReader)
	if err != nil {
		fmt.Println("Failed to create requestuest:", err)
		os.Exit(1)
	}

	request.Header.Add("Accept", "application/json")
	request.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	// perform request
	client := &http.Client{}
	response, err := client.Do(request)
	if response.StatusCode == 200 {
		successMessageToOutput(FROM_NAME, toName, subject, message)
	} else {
		var data map[string]interface{}
		bodyBytes, _ := ioutil.ReadAll(response.Body)
		err := json.Unmarshal(bodyBytes, &data)
		if err == nil {
			fmt.Println("Response:", data)
		}

		errorMsg := fmt.Sprintf("Status code: %s Body: %s", response.StatusCode, response.Body)
		errorMessageToOutput(errorMsg)

		os.Exit(1)
	}
}
