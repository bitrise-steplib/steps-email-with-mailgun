# Email with Mailgun

The new Email with Mailgun step.

Send emails with Mailgun [https://mailgun.com](https://mailgun.com)
Watch out, your emails can land in the spam/junk folder.
This Step is part of the [Open StepLib](http://www.steplib.com/), you can find its StepLib page [here](http://www.steplib.com/step/mailgun-email)


Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

*Check the `bitrise.yml` file for required inputs which have to be
added to your `.bitrise.secrets.yml` file!*


# Input Environment Variables
- **api_key**

	at [https://www.mailgun.com/cp](https://www.mailgun.com/cp)
- **domain**

	the domain from which the e-mail will be sent; you can set it at [https://www.mailgun.com/cp](https://www.mailgun.com/cp)
- **send_to**

	the receiver of the e-mail
- **subject**

	the subject of the e-mail
- **message**

	the message of the e-mail
