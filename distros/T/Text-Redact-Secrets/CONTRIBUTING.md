# Contributing

Thank you for wanting to help. Text-Redact-Secrets welcomes **bug
reports and feature requests**, as issues on the repository MetaCPAN
links to. It doesn't accept pull requests.

## Why no pull requests

Text-Redact-Secrets is written by Iain Campbell, with Claude, and every
change goes through the same checks: tests across every Perl from 5.36
on, with floors on how much of the code they cover, and documentation
written alongside the code. Owning every line keeps the credit honest,
and the code safe to depend on: no one else's code can be merged in, by
mistake or by design.

A good report helps more than a pull request would. Its reproduction
becomes the failing test that comes before the fix. If you have a fix in
mind, sketch it in the issue: it will be written into the code with
tests, and you'll be thanked by name in `Changes`.

## The rules

Most of the rules that find secrets are gitleaks', carried over by a
script, not written here. gitleaks adds no more rules, so a kind of
secret none of them finds is welcome here, as an issue: it may become
one of the distribution's own rules, which are written by hand. Report
it here too when gitleaks finds a secret and Text::Redact::Secrets
doesn't, as that's how a rule was carried over. A rule of gitleaks'
that matches what isn't a secret is welcome here as well, so that
it's known, though it can't be changed here: gitleaks' rules are kept
as gitleaks has them, and only
[gitleaks](https://github.com/gitleaks/gitleaks) can fix one.

## A good bug report

- The versions: Text::Redact::Secrets'
  (`perl -MText::Redact::Secrets -E 'say Text::Redact::Secrets->VERSION'`),
  and Perl's.
- The smallest string that shows the problem, with any secret in it
  made up: never a real one.
- What you expected, and what happened instead.

## Security

Please don't report a vulnerability in a public issue. See
[SECURITY.md](SECURITY.md).

## What to expect

Text-Redact-Secrets is one person's project, kept up as time allows.
Reports are read, but a reply can take a while.
