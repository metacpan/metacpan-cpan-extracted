# Security Policy

This is the security policy for the Perl WebDyne distribution.

This policy was updated on 2026-08-10.

## Reporting a Security Vulnerability

Please report security vulnerabilities via GitHub private vulnerability
reporting for this repository:

https://github.com/aspeer/WebDyne/security/advisories/new

GitHub private vulnerability reporting is enabled for this repository and is
the preferred reporting point.

If you cannot use GitHub, report the issue privately by email to the current
project maintainer:

Andrew Speer <andrew.speer@isolutions.com.au>

Please do not report security vulnerabilities through public GitHub issues,
public pull requests, RT, mailing lists, social media, chat channels, or other
public forums.

Please include enough detail to reproduce and assess the issue, including:

- the affected WebDyne version
- the affected Perl version and operating system, if relevant
- a proof of concept, test case, or reproduction steps
- relevant logs, code snippets, configuration, or request/response examples
- whether the issue is known to be actively exploited
- whether you want public credit when the issue is disclosed

Do not include passwords, tokens, private keys, personal data, or other
sensitive information in the report unless it is strictly necessary and safe
to share with the maintainers.

If you would like help triaging the issue, need CVE coordination, cannot reach
the maintainer, or believe the issue is being actively exploited, you may also
copy the CPAN Security Group (CPANSec):

cpan-security@security.metacpan.org

For signs of a compromised CPAN/PAUSE account, contact the PAUSE
administrators privately:

pause-admin@perl.org

## Supported Versions

Security fixes are normally made against the latest WebDyne release on CPAN.
Older releases are not routinely supported unless the maintainer decides a
backport is practical and necessary for downstream users.

If this policy or the latest release is more than two years old, check for a
newer WebDyne release on CPAN or in the main GitHub repository before relying
on the contact and support information here.

## Handling and Disclosure

The maintainer will aim to acknowledge security reports as soon as practical,
investigate the report, and coordinate a fix and public disclosure where
appropriate. WebDyne is maintained by a volunteer maintainer, so exact response
times cannot be guaranteed.

Please do not publicly disclose the vulnerability, exploit details, patches, or
mitigation advice until a coordinated disclosure date has passed or the issue
has been made public by the maintainer or CPANSec.

## Scope

This policy applies to vulnerabilities in the WebDyne distribution itself.
Installation problems, general bugs, feature requests, documentation issues,
and non-security support questions should use the normal public GitHub issue
tracker.

This policy is based on guidance from the CPAN Security Group:

https://security.metacpan.org/docs/guides/security-policy-for-authors.html
