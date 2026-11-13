# Security Policy for the Twilio distribution

Report security issues by email to Francisco Zarabozo <zarabozo@cpan.org>.

This is the security policy for the Perl distribution Twilio. The latest version
is in the repository at <https://github.com/Zarabozo/Twilio/blob/main/SECURITY.md>.

It is based on the CPAN Security Group's guidelines for adding a security policy
to Perl distributions.

## How to report a security vulnerability

Send the report by email to <zarabozo@cpan.org>. Include as many details as you
can: the version of Twilio and of Perl, code or a test case that shows the
problem, and what an attacker could do with it.

Never include real credentials, such as an Auth Token, an API key's secret, an
OAuth client secret or a private key, in a report or a test case. If yours were
exposed, change them in the Twilio Console first.

Please don't report a vulnerability through GitHub issues, pull requests or any
other public place, and don't disclose it publicly until a fixed release is out
or a date for disclosure has been agreed.

If you'd like help with triage, or the issue is being actively exploited, you
can also send a copy of the report to the CPAN Security Group (CPANSec) at
<cpan-security@security.metacpan.org>.

## Response to reports

The maintainer will acknowledge your report as soon as possible. The project is
maintained by one person, in their own time, so a quick answer can't be
guaranteed. If you've had no answer within a week, send a reminder, or contact
CPANSec.

Once the problem is confirmed, the fix will be released with a note in
`Changes`. If you want to be credited, say how.

## What this policy covers

It covers security vulnerabilities in the code of the Twilio distribution: the
HTTP client and its authentication, the validation of webhook signatures, access
tokens and other JWTs, TwiML, and the generated REST classes. A vulnerability is
anything that lets someone run code, reach data or resources they shouldn't, get
hold of credentials, or forge or replay requests the library should refuse.

It doesn't cover:

- Twilio's service itself, or Twilio's official libraries. Report those to
  Twilio: <https://www.twilio.com/en-us/security>.
- Modules this distribution depends on, or Perl itself, unless the way Twilio
  uses them makes the problem possible. Report those to their own maintainers,
  or to CPANSec.
- Software that uses this distribution.

## Supported versions

Only the latest release gets security fixes.

## Installation and usage issues

If a problem comes from how Twilio is installed or used, rather than from its
code, it is not a security vulnerability of this distribution. Report it as a
bug through GitHub issues: <https://github.com/Zarabozo/Twilio/issues>.
