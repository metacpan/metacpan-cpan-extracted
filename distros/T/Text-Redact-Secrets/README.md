[![Actions Status](https://github.com/nukopian/Text-Redact-Secrets/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nukopian/Text-Redact-Secrets/actions?workflow=test)
[![CPAN](https://img.shields.io/cpan/v/Text-Redact-Secrets)](https://metacpan.org/release/Text-Redact-Secrets) [![Kwalitee](https://cpants.cpanauthors.org/dist/Text-Redact-Secrets.svg)](https://cpants.cpanauthors.org/dist/Text-Redact-Secrets)

# Text-Redact-Secrets

Find secrets in text by gitleaks' rules, and redact them.

Text that might hold a secret, such as a dump written to a log, should
be safe to write. Text::Redact::Secrets puts `*REDACTED*` in place of
each secret it finds in a string, with `redact`, or reports each, with
`find`, by the rules of [gitleaks](https://github.com/gitleaks/gitleaks):
a maintained set of regexes, keywords, entropies and allowlists,
carried over from gitleaks with their meaning unchanged. Beside them
are rules of its own, for secrets gitleaks has no rule for, such as a
password in a URL like `postgres://user:password@host/db`.

```perl
use Text::Redact::Secrets qw(find redact);

# The text with each secret in it replaced by *REDACTED*.
print {$log} redact($text);

# Each secret in the text, with the rule that found it.
for my $found (find($text)) {
    say "$found->{rule} at $found->{offset}";
}
```

## Installing

From CPAN:

```
cpanm Text::Redact::Secrets
```

Or the latest from GitHub:

```
cpanm https://github.com/nukopian/Text-Redact-Secrets.git
```

It needs Perl 5.36 or later, and nothing beyond its core modules.

## What it won't find

It finds what its rules describe, and nothing else, so redacted text
can still hold a secret: a short or ordinary password isn't found, nor
a secret that's been base64-encoded. The module's POD says more.

## Keeping the rules current

The rules can't be updated where the module is installed. Each set is
carried over from a gitleaks release, tested, and released as a new
version: one that brings new rules moves the middle number, as from
v1.0.0 to v1.1.0. To have the newest rules, install the module again,
which brings the newest version:

```
cpanm Text::Redact::Secrets
```

[Text::Redact::Secrets::Rules::Gitleaks](https://metacpan.org/pod/Text%3A%3ARedact%3A%3ASecrets%3A%3ARules%3A%3AGitleaks) names the gitleaks release
the installed rules came from.

## Licence

Copyright (c) 2026 by Iain Campbell. This is free software; you can
redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself, except for gitleaks' rules, which
are under gitleaks' MIT licence, in `LICENSE-gitleaks`. See the file
`LICENSE`.

## Acknowledgements

Designed and created by Iain Campbell, in collaboration with Claude,
Anthropic's AI model. The rules for finding secrets are gitleaks', by
Zachary Rice and its contributors, but for the module's own, which
are Iain's and Claude's.
