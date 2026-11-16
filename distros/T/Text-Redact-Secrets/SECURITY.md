# Security

This is the security policy for Text-Redact-Secrets, the Perl
distribution of Text::Redact::Secrets.

## Reporting a vulnerability

Please report a vulnerability privately, never in a public issue,
either way:

- on GitHub, with **Report a vulnerability** on the Security tab of the
  repository MetaCPAN links to (Security → Advisories → Report a
  vulnerability);
- by email, to the maintainer, Iain Campbell, at <cpanic@cpan.org>.

If you can't reach the maintainer, or have had no reply after a
reasonable time, contact the CPAN Security Group, at
<cpan-security@security.metacpan.org>.

A useful report has the version of Text::Redact::Secrets, and of Perl;
a reproduction, as small as you can make it; and what an attacker could
do with it. You'll get a reply when it has been read, and credit in the
advisory and in `Changes` if you'd like it.

## Scope

This policy covers the modules in this distribution. Most of their
rules come from [gitleaks](https://github.com/gitleaks/gitleaks), so a
report may belong to gitleaks, to us, or to both:

- **A flaw in one of gitleaks' rules**, one that lets through the kind
  of secret it's meant to find in gitleaks too, is a vulnerability in
  gitleaks. Please report it privately to gitleaks, as
  [its security policy](https://github.com/gitleaks/gitleaks/blob/master/SECURITY.md)
  asks, by its
  [private vulnerability reporting](https://github.com/gitleaks/gitleaks/security/advisories/new),
  and privately to us too, as we carry the rule and can warn our users
  while it's fixed.
- **A flaw in this distribution** is ours alone: a secret that `redact`
  lets through where gitleaks wouldn't, a rule carried over wrongly, or
  a regex that takes too long, in Perl, on text an attacker can choose.
- **A kind of secret no rule finds** isn't a vulnerability. It's
  welcome as an ordinary issue, as CONTRIBUTING.md says: gitleaks adds
  no more rules, but it may become one of ours.

If you're not sure where a report belongs, send it privately to us, as
above, and we'll pass on to gitleaks whatever is theirs.

A vulnerability in a module that uses this one belongs to that project.

## Supported versions

Only the latest release is supported, on Perl 5.36 or later.

## Fixes

Fixes go into a new release, and `Changes` says what it fixes. A
release on CPAN is never changed: a version with a vulnerability may be
deleted from CPAN, though BackPAN keeps it, and the fixed one replaces
it.

This project doesn't pay for reports.
