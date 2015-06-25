package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"

	"./markdownlog"
)

const (
	BASE_URL  = "https://api.mailgun.net/v3"
	FROM_NAME = "Bitrise Mailgun Step <postmaster@$MAILGUN_DOMAIN>"
)

var (
	apiKey string
	domain string

	toName  string
	message string

	subject string

	errorToName  string
	errorMessage string

	errorSubject string
)

type Client struct {
	ApiKey string
	Domain string
	Uri    string
}

type MessageRequest struct {
	// - required
	FromName string
	ToName   string
	Message  string
	// - optional
	Subject string
}

func buildMessageRequest(isBuildFailedMode bool) MessageRequest {
	req := MessageRequest{
		FromName: FROM_NAME,
	}

	if isBuildFailedMode {
		if errorToName == "" {
			fmt.Println("Build failed, but no MAILGUN_ERROR_SEND_TO defined, use default")
		} else {
			toName = errorToName
		}
	}
	req.ToName = toName

	if isBuildFailedMode {
		if errorMessage == "" {
			fmt.Println("Build failed, but no MAILGUN_ERROR_EMAIL_MESSAGE defined, use default")
		} else {
			message = errorMessage
		}
	}
	req.Message = message

	if isBuildFailedMode {
		if errorSubject == "" {
			fmt.Println("Build failed, but no MAILGUN_ERROR_EMAIL_SUBJECT defined, use default")
		} else {
			subject = errorSubject
		}
	}
	req.Subject = subject

	return req
}

func urlValuesFromMessageRequest(req MessageRequest) (url.Values, error) {
	payload := url.Values{
		"from":    {req.FromName},
		"to":      {req.ToName},
		"message": {req.Message},
	}
	if len(req.Subject) > 0 {
		payload.Add("subject", req.Subject)
	}
	return payload, nil
}

func NewClient(apiKey, domain string) Client {
	uri := fmt.Sprintf("https://api:key-%s@api.mailgun.net/v3/%s/messages", url.QueryEscape(apiKey), url.QueryEscape(domain))
	return Client{ApiKey: apiKey, Domain: domain, Uri: uri}
}

func (c *Client) PostMessage(req MessageRequest) error {
	payload, err := urlValuesFromMessageRequest(req)
	if err != nil {
		return err
	}

	resp, err := http.PostForm(c.Uri, payload)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	msgResp := &struct{ Status string }{}
	if err := json.Unmarshal(body, msgResp); err != nil {
		return err
	}
	/*
		if msgResp.Status != ResponseStatusSent {
			return getError(body)
		}
	*/

	return nil
}

func errorMessageToOutput(msg string) error {
	message := "Message send failed!\n"
	message = message + "Error message:\n"
	message = message + msg

	return markdownlog.ErrorSectionToOutput(message)
}

func successMessageToOutput(from, roomId, msg string) error {
	message := "Message successfully sent!\n"
	message = message + "From:\n"
	message = message + from + "\n"
	message = message + "To Romm:\n"
	message = message + roomId + "\n"
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

	// input validation
	// required
	apiKey = os.Getenv("MAILGUN_API_KEY")
	if apiKey == "" {
		errorMessageToOutput("$MAILGUN_API_KEY is not provided!")
		os.Exit(1)
	}
	domain = os.Getenv("MAILGUN_DOMAIN")
	if domain == "" {
		errorMessageToOutput("$MAILGUN_DOMAIN is not provided!")
		os.Exit(1)
	}
	toName = os.Getenv("MAILGUN_SEND_TO")
	if toName == "" {
		errorMessageToOutput("$MAILGUN_SEND_TO is not provided!")
		os.Exit(1)
	}
	message = os.Getenv("MAILGUN_EMAIL_MESSAGE")
	if message == "" {
		errorMessageToOutput("$MAILGUN_EMAIL_MESSAGE is not provided!")
		os.Exit(1)
	}
	//optional
	subject = os.Getenv("MAILGUN_EMAIL_SUBJECT")
	if subject == "" {
		markdownlog.SectionToOutput("$MAILGUN_EMAIL_SUBJECT is not provided!")
	}
	errorToName = os.Getenv("MAILGUN_ERROR_SEND_TO")
	if errorToName == "" {
		markdownlog.SectionToOutput("$MAILGUN_ERROR_SEND_TO is not provided!")
	}
	errorSubject = os.Getenv("MAILGUN_ERROR_EMAIL_SUBJECT")
	if errorSubject == "" {
		markdownlog.SectionToOutput("$MAILGUN_ERROR_EMAIL_SUBJECT is not provided!")
	}
	errorMessage = os.Getenv("MAILGUN_ERROR_EMAIL_MESSAGE")
	if errorMessage == "" {
		markdownlog.SectionToOutput("$MAILGUN_ERROR_EMAIL_MESSAGE is not provided!")
	}

	// perform step
	isBuildFailedMode := (os.Getenv("STEPLIB_BUILD_STATUS") != "0")
	req := buildMessageRequest(isBuildFailedMode)
	c := NewClient(apiKey, domain)
	if err := c.PostMessage(req); err != nil {
		fmt.Println(err)
	}
}
