package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
)

// -----------------------
// --- Functions
// -----------------------

func logFail(format string, v ...interface{}) {
	errorMsg := fmt.Sprintf(format, v...)
	fmt.Printf("\x1b[31;1m%s\x1b[0m\n", errorMsg)
	os.Exit(1)
}

func logWarn(format string, v ...interface{}) {
	errorMsg := fmt.Sprintf(format, v...)
	fmt.Printf("\x1b[33;1m%s\x1b[0m\n", errorMsg)
}

func logInfo(format string, v ...interface{}) {
	fmt.Println()
	errorMsg := fmt.Sprintf(format, v...)
	fmt.Printf("\x1b[34;1m%s\x1b[0m\n", errorMsg)
}

func logDetails(format string, v ...interface{}) {
	errorMsg := fmt.Sprintf(format, v...)
	fmt.Printf("  %s\n", errorMsg)
}

func logDone(format string, v ...interface{}) {
	errorMsg := fmt.Sprintf(format, v...)
	fmt.Printf("  \x1b[32;1m%s\x1b[0m\n", errorMsg)
}

func validateRequiredInput(key string) string {
	value := os.Getenv(key)
	if value == "" {
		logFail("missing required input: %s", key)
	}
	return value
}

func strip(str string) string {
	dirty := true
	strippedStr := str
	for dirty {
		hasWhiteSpacePrefix := false
		if strings.HasPrefix(strippedStr, " ") {
			hasWhiteSpacePrefix = true
			strippedStr = strings.TrimPrefix(strippedStr, " ")
		}

		hasWhiteSpaceSuffix := false
		if strings.HasSuffix(strippedStr, " ") {
			hasWhiteSpaceSuffix = true
			strippedStr = strings.TrimSuffix(strippedStr, " ")
		}

		if !hasWhiteSpacePrefix && !hasWhiteSpaceSuffix {
			dirty = false
		}
	}
	return strippedStr
}

func genericIsPathExists(pth string) (os.FileInfo, bool, error) {
	if pth == "" {
		return nil, false, errors.New("No path provided")
	}
	fileInf, err := os.Stat(pth)
	if err == nil {
		return fileInf, true, nil
	}
	if os.IsNotExist(err) {
		return nil, false, nil
	}
	return fileInf, false, err
}

func isPathExists(pth string) (bool, error) {
	_, isExists, err := genericIsPathExists(pth)
	return isExists, err
}

func createRequest(url string, fields map[string]string, attachments []string) (*http.Request, error) {
	var b bytes.Buffer
	w := multipart.NewWriter(&b)

	// Add fields
	for key, value := range fields {
		if err := w.WriteField(key, value); err != nil {
			return nil, err
		}
	}

	// Add files
	for _, file := range attachments {
		f, err := os.Open(file)
		if err != nil {
			return nil, err
		}
		fw, err := w.CreateFormFile("attachment", file)
		if err != nil {
			return nil, err
		}
		if _, err = io.Copy(fw, f); err != nil {
			return nil, err
		}
	}

	if err := w.Close(); err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", url, &b)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", w.FormDataContentType())

	return req, nil
}

// -----------------------
// --- Main
// -----------------------

func main() {
	//
	// Validate options
	logInfo("Configs:")
	logDetails("api_key: %s", os.Getenv("api_key"))
	logDetails("domain: %s", os.Getenv("domain"))
	logDetails("from_email: %s", os.Getenv("from_email"))
	logDetails("send_to: %s", os.Getenv("send_to"))
	logDetails("subject: %s", os.Getenv("subject"))
	logDetails("message: %s", os.Getenv("message"))
	logDetails("error_message: %s", os.Getenv("error_message"))
	logDetails("message_format: %s", os.Getenv("message_format"))
	logDetails("attachments: %s", os.Getenv("attachments"))

	apiKey := validateRequiredInput("api_key")
	domain := validateRequiredInput("domain")
	fromEmail := validateRequiredInput("from_email")
	sendTo := validateRequiredInput("send_to")
	subject := validateRequiredInput("subject")
	message := validateRequiredInput("message")
	messageFormat := validateRequiredInput("message_format")

	errorMessage := os.Getenv("error_message")
	attachmentList := os.Getenv("attachments")

	isBuildFailedMode := (os.Getenv("STEPLIB_BUILD_STATUS") != "0")
	if isBuildFailedMode && errorMessage != "" {
		message = errorMessage
	}

	attachments := []string{}
	if attachmentList != "" {
		split := strings.Split(attachmentList, ",")
		for _, item := range split {
			filePath := strip(item)
			if exist, err := isPathExists(filePath); err != nil {
				logFail("failed to check if path (%s) exist, error: %s", filePath, err)
			} else if !exist {
				logFail("file not exist at (%s)", filePath)
			}

			attachments = append(attachments, filePath)
		}
	}

	//
	// Create request
	logInfo("Performing request")

	requestURL := fmt.Sprintf("https://api.mailgun.net/v2/%s/messages", domain)

	fields := map[string]string{
		"from":    fromEmail,
		"to":      sendTo,
		"subject": subject,
	}

	switch messageFormat {
	case "html":
		fields["html"] = message
	case "text":
		fields["text"] = message
	default:
		logFail("invalid message_format: %s, available options [html, text]", messageFormat)
	}

	request, err := createRequest(requestURL, fields, attachments)
	if err != nil {
		logFail("Failed to create request, error: %#v", err)
	}
	request.SetBasicAuth("api", apiKey)

	client := http.Client{}
	response, requestErr := client.Do(request)
	if requestErr != nil {
		logFail("Performing request failed, error: %#v", requestErr)
	}

	defer func() {
		if err := response.Body.Close(); err != nil {
			logWarn("Failed to close response body:", err)
		}
	}()
	contents, readErr := ioutil.ReadAll(response.Body)
	if readErr != nil {
		logWarn("Failed to read response body, error: %#v", readErr)
	}

	logInfo("response content: %s", contents)
	logDetails("status code: %d", response.StatusCode)
}
